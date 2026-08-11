/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
const {
  onDocumentUpdated,
  onDocumentCreated,
} = require("firebase-functions/v2/firestore");
const {onCall} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({maxInstances: 10});

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

/**
 * CONTOH #1 -- notifikasi event-triggered ("Status pesanan").
 *
 * Jalan otomatis tiap dokumen order di users/{userId}/orders/{orderId}
 * ke-update. Cek dulu notif_prefs.status_pesanan user itu di Firestore
 * sebelum kirim push -- ini titik yang bikin toggle di NotificationsScreen
 * beneran ngefek, bukan cuma preferensi yang nganggur di device.
 *
 * NOTE: sesuaikan kondisi "kapan harus notif" (`beforeStatus !==
 * afterStatus`) dan isi pesan dengan alur bisnis order kamu yang
 * sebenarnya -- ini kerangka contoh, bukan versi final.
 */
exports.onOrderStatusChanged = onDocumentUpdated(
    "users/{userId}/orders/{orderId}",
    async (event) => {
      const before = event.data.before.data();
      const after = event.data.after.data();
      if (before.status === after.status) return;

      const userId = event.params.userId;
      const userSnap = await admin.firestore()
          .collection("users").doc(userId).get();
      const user = userSnap.data();
      if (!user) return;

      // Baris ini yang jadi inti "opsi 2": cek preferensi sebelum kirim.
      const wantsNotif = user.notif_prefs?.status_pesanan !== false;
      if (!wantsNotif || !user.fcm_token) {
        logger.info(`Skip notif status_pesanan ${userId} (off/tanpa token)`);
        return;
      }

      await admin.messaging().send({
        token: user.fcm_token,
        notification: {
          title: "Status pesanan diperbarui",
          body: `Pesanan #${event.params.orderId} sekarang: ${after.status}`,
        },
        data: {
          type: "status_pesanan",
          orderId: event.params.orderId,
        },
      });
    },
);

/**
 * FIX GAP -- sinkronisasi `grace_started_at` di subscriptions/{subId}.
 *
 * LATAR BELAKANG: SubscriptionRepository.updateSubscriptionStatus() di sisi
 * Flutter SUDAH ngurus auto-isi/hapus `grace_started_at` (lihat
 * lib/repositories/subscription_repository.dart) -- TAPI itu cuma kepanggil
 * kalau APLIKASI FLUTTER sendiri yang mengubah status. Status "beneran"
 * (dari pembayaran Stripe gagal/berhasil) ditulis oleh backend Vercel
 * terpisah (`netwash-stripe-backend.vercel.app`, lihat stripe_service.dart)
 * yang menulis LANGSUNG ke Firestore pakai Admin SDK -- SAMA SEKALI TIDAK
 * lewat kode Dart di atas. Tanpa trigger ini, `grace_started_at` bisa gak
 * pernah keisi di dunia nyata, dan SubscriptionService.isInGracePeriod()
 * di app akan SELALU false (langsung dianggap expired begitu status jadi
 * 'past_due', tanpa masa tenggang sama sekali).
 *
 * Trigger Firestore ini jalan di LEVEL DATABASE, jadi ngefek nulis dari
 * SUMBER MANA PUN (webhook Vercel, Flutter, Firebase Console manual, dll)
 * -- bukan cuma dari kode Dart. Logic-nya sengaja dibikin sama persis
 * dengan SubscriptionRepository.updateSubscriptionStatus() di sisi Dart,
 * supaya dua-duanya konsisten:
 * - transisi ke 'past_due' -> set grace_started_at = sekarang, HANYA kalau
 *   belum ada nilai (idempotent terhadap webhook retry/duplicate event).
 * - transisi ke 'active'/'trialing' -> hapus lagi grace_started_at.
 * - status lain, atau status tidak berubah sama sekali -> tidak ngapa-ngapain.
 *
 * AMAN dari infinite loop: update yang dilakukan function ini sendiri akan
 * memicu trigger lagi, tapi saat itu `before.status === after.status`
 * (sama-sama 'past_due' atau sama-sama 'active'), jadi langsung `return`
 * di baris pertama sebelum nulis apa pun lagi.
 */
exports.onSubscriptionStatusChanged = onDocumentUpdated(
    "users/{userId}/subscriptions/{subscriptionId}",
    async (event) => {
      const before = event.data.before.data();
      const after = event.data.after.data();
      if (before.status === after.status) return;

      if (after.status === "past_due") {
        if (after.grace_started_at) return; // sudah ada, jangan digeser
        await event.data.after.ref.update({
          grace_started_at: admin.firestore.Timestamp.now(),
        });
        logger.info(
            `grace_started_at diset untuk subscription ` +
            `${event.params.subscriptionId} (user ${event.params.userId})`,
        );
        return;
      }

      if (after.status === "active" || after.status === "trialing") {
        if (!after.grace_started_at) return; // sudah kosong, gak perlu nulis
        await event.data.after.ref.update({
          grace_started_at: admin.firestore.FieldValue.delete(),
        });
        logger.info(
            `grace_started_at dihapus untuk subscription ` +
            `${event.params.subscriptionId} (user ${event.params.userId})`,
        );
      }
    },
);

/**
 * CONTOH #2 -- notifikasi broadcast tertarget ("Promo dan diskon").
 *
 * Callable function: dipanggil manual dari admin panel/dashboard tiap
 * ada promo baru. Query semua user yang notif_prefs.promo == true DAN
 * punya fcm_token, baru kirim batch (maks 500 token per panggilan
 * sendEachForMulticast -- looping kalau usernya lebih banyak dari itu).
 */
exports.sendPromoBroadcast = onCall(async (request) => {
  const {title, body} = request.data;
  if (!title || !body) {
    throw new Error("title dan body wajib diisi");
  }

  const usersSnap = await admin
      .firestore()
      .collection("users")
      .where("notif_prefs.promo", "==", true)
      .get();

  const tokens = usersSnap.docs
      .map((doc) => doc.data().fcm_token)
      .filter((token) => typeof token === "string" && token.length > 0);

  if (tokens.length === 0) {
    return {sent: 0};
  }

  const response = await admin.messaging().sendEachForMulticast({
    tokens,
    notification: {title, body},
    data: {type: "promo"},
  });

  logger.info(
      `Promo broadcast: ${response.successCount} terkirim, ` +
      `${response.failureCount} gagal`,
  );
  return {sent: response.successCount, failed: response.failureCount};
});

/**
 * CONTOH #3 -- notifikasi terjadwal ("Pengingat").
 *
 * Jalan otomatis tiap jam. Order disimpan per-user di
 * `users/{userId}/orders/{orderId}` (lihat OrderRepository), jadi buat
 * nyisir SEMUA user sekaligus dipakai collectionGroup('orders') --
 * bukan loop manual per dokumen users/.
 *
 * Dua hal yang dicek:
 * 1. `pickup_date` mendekat (order_type == 'pickup', belum dijemput)
 * 2. `delivery_date` mendekat (delivery_type == 'delivery', siap diantar)
 *
 * PENTING -- asumsi yang perlu kamu cek/sesuaikan:
 * - Field `pickup_reminder_sent` / `delivery_reminder_sent` (boolean)
 *   BELUM ada di model Order kamu. Ini dipakai biar reminder yang sama
 *   tidak terkirim berkali-kali tiap function jalan (tiap jam). Tambahin
 *   dua field ini ke Order (default false / tidak diisi), atau ganti
 *   strategi dedup-nya kalau kamu punya cara lain.
 * - Window pengingat aku set H-2 jam (REMINDER_WINDOW_HOURS). Kondisi
 *   status yang dianggap "belum selesai" (`PENDING_PICKUP_STATUSES` /
 *   `READY_FOR_DELIVERY_STATUSES`) juga cuma tebakan dari alur status di
 *   OrderStatus enum -- sesuaikan dengan bisnis proses kamu yang beneran.
 * - Query di bawah pakai range filter (pickup_date/delivery_date) +
 *   equality filter (order_type/delivery_type) sekaligus -> Firestore
 *   BUTUH composite index. Pertama kali deploy & jalan, cek log function;
 *   Firebase biasanya kasih link langsung buat generate index-nya, atau
 *   tambahin manual ke firestore.indexes.json.
 */
const REMINDER_WINDOW_HOURS = 2;
const PENDING_PICKUP_STATUSES = ["pending", "confirmed"];
const READY_FOR_DELIVERY_STATUSES = ["ready"];

/**
 * Kirim satu notifikasi pengingat ke owner akun (users/{userId}) yang
 * punya order ini, dengan cek notif_prefs.pengingat + fcm_token dulu.
 *
 * @param {FirebaseFirestore.DocumentSnapshot} orderSnap Snapshot dokumen
 *   order (di bawah users/{userId}/orders/{orderId}).
 * @param {{title: string, body: string, extraData: object}} payload Isi
 *   notifikasi yang mau dikirim.
 * @return {Promise<boolean>} true kalau notif jadi terkirim (dipakai
 *   buat mark reminder_sent).
 */
async function _sendPengingatNotif(orderSnap, {title, body, extraData}) {
  const userRef = orderSnap.ref.parent.parent; // users/{userId}
  if (!userRef) return false;

  const userSnap = await userRef.get();
  const user = userSnap.data();
  if (!user) return false;

  const wantsNotif = user.notif_prefs?.pengingat !== false;
  if (!wantsNotif || !user.fcm_token) {
    logger.info(`Skip pengingat untuk ${userRef.id} (off/tanpa token)`);
    return false;
  }

  await admin.messaging().send({
    token: user.fcm_token,
    notification: {title, body},
    data: {type: "pengingat", orderId: orderSnap.id, ...extraData},
  });
  return true;
}

exports.sendPengingatReminders = onSchedule(
    {schedule: "every 60 minutes", timeZone: "Asia/Jakarta"},
    async () => {
      const now = admin.firestore.Timestamp.now();
      const windowEnd = admin.firestore.Timestamp.fromMillis(
          now.toMillis() + REMINDER_WINDOW_HOURS * 60 * 60 * 1000,
      );

      // --- 1) Pengingat jemput ---
      const pickupSnap = await admin
          .firestore()
          .collectionGroup("orders")
          .where("order_type", "==", "pickup")
          .where("pickup_date", ">=", now)
          .where("pickup_date", "<=", windowEnd)
          .get();

      let pickupSent = 0;
      for (const doc of pickupSnap.docs) {
        const order = doc.data();
        if (order.pickup_reminder_sent === true) continue;
        if (!PENDING_PICKUP_STATUSES.includes(order.status)) continue;

        const sent = await _sendPengingatNotif(doc, {
          title: "Jadwal jemput sebentar lagi",
          body: `Pesanan #${order.order_number ?? doc.id} ` +
              "dijadwalkan dijemput sebentar lagi.",
          extraData: {reminderType: "pickup"},
        });
        if (sent) {
          await doc.ref.update({pickup_reminder_sent: true});
          pickupSent++;
        }
      }

      // --- 2) Pengingat antar ---
      const deliverySnap = await admin
          .firestore()
          .collectionGroup("orders")
          .where("delivery_type", "==", "delivery")
          .where("delivery_date", ">=", now)
          .where("delivery_date", "<=", windowEnd)
          .get();

      let deliverySent = 0;
      for (const doc of deliverySnap.docs) {
        const order = doc.data();
        if (order.delivery_reminder_sent === true) continue;
        if (!READY_FOR_DELIVERY_STATUSES.includes(order.status)) continue;

        const sent = await _sendPengingatNotif(doc, {
          title: "Jadwal antar sebentar lagi",
          body: `Pesanan #${order.order_number ?? doc.id} ` +
              "dijadwalkan diantar sebentar lagi.",
          extraData: {reminderType: "delivery"},
        });
        if (sent) {
          await doc.ref.update({delivery_reminder_sent: true});
          deliverySent++;
        }
      }

      logger.info(
          `Pengingat: ${pickupSent} jemput, ${deliverySent} antar terkirim`,
      );
    },
);

/**
 * FIX GAP (poin 12) -- reminder H-3 / H-1 sebelum current_period_end.
 *
 * LATAR BELAKANG: sebelum ini, satu-satunya sinyal ke pengguna soal
 * subscription mau/sudah bermasalah adalah banner di dashboard
 * (_buildSubscriptionBanner) -- dan itu SIFATNYA REAKTIF, baru muncul
 * SETELAH status berubah jadi 'past_due'. Tidak ada apa pun yang
 * mengingatkan SEBELUM tanggal jatuh tempo. Function ini nutup gap itu:
 * jalan sekali sehari, cek semua subscription yang masih 'active'/
 * 'trialing', dan kirim notifikasi kalau sisa hari ke `current_period_end`
 * pas H-3 atau H-1.
 *
 * SYARAT: field `current_period_end` di dokumen subscription harus
 * terisi -- ini yang baru diperbaiki di stripe-webhook.js (checkout.
 * session.completed & customer.subscription.updated sekarang keduanya
 * mengisi field ini). Dokumen lama yang dibuat SEBELUM fix itu mungkin
 * tidak punya field ini -- di-skip dengan log warning, bukan error.
 *
 * DEDUP TANPA PERLU RESET MANUAL: reminder H-3 & H-1 masing-masing
 * disimpan sebagai `reminder_h3_sent_for_period_end` / `..._h1_...`
 * berisi NILAI current_period_end saat reminder itu dikirim (bukan
 * cuma boolean true/false). Jadi begitu siklus billing lanjut ke bulan
 * berikutnya (current_period_end berubah lewat webhook Stripe), nilai
 * yang tersimpan otomatis jadi "basi" dan reminder bulan berikutnya
 * tetap bisa terkirim lagi -- tanpa perlu ada langkah reset field secara
 * eksplisit di tempat lain.
 *
 * NOTIFIKASI INI SENGAJA TIDAK DI-GATE oleh notif_prefs mana pun.
 * Kategori notif_prefs yang ada sekarang (status_pesanan, promo,
 * pengingat, chat_cs) tidak ada yang cocok secara makna untuk reminder
 * tagihan/langganan -- "pengingat" existing spesifik soal jadwal jemput/
 * antar cucian (lihat _sendPengingatNotif & sendPengingatReminders di
 * atas). Karena reminder ini soal risiko akun ke-restrict kalau
 * terlewat, defaultnya SELALU kirim asal `fcm_token` ada. Kalau kamu mau
 * ini tetap bisa dimatikan user (misal toggle baru "Tagihan &
 * langganan"), tinggal tambah field notif_prefs baru dan cek di sini
 * sama seperti pola-pola di atas.
 *
 * CATATAN QUERY: sengaja TIDAK menambah filter range pada
 * current_period_end di query Firestore (cuma filter status via `in`),
 * supaya tidak butuh composite index tambahan. Perhitungan "H-3/H-1"
 * dilakukan di JS setelah data diambil. Kalau jumlah subscription aktif
 * sudah sangat banyak, ini bisa dioptimasi lagi nanti dengan composite
 * index + range filter.
 */
const RENEWAL_REMINDER_DAYS_BEFORE = [3, 1];

/**
 * Kirim satu notifikasi reminder ke owner akun (users/{userId}) pemilik
 * subscription ini. Beda dari _sendPengingatNotif (order) -- tidak cek
 * notif_prefs sama sekali, lihat penjelasan di komentar function utama.
 *
 * @param {FirebaseFirestore.DocumentSnapshot} subscriptionSnap Snapshot
 *   dokumen subscription (di bawah users/{userId}/subscriptions/{id}).
 * @param {{title: string, body: string, extraData: object}} payload Isi
 *   notifikasi yang mau dikirim.
 * @return {Promise<boolean>} true kalau notif jadi terkirim.
 */
async function _sendSubscriptionReminderNotif(subscriptionSnap, {title, body, extraData}) {
  const userRef = subscriptionSnap.ref.parent.parent; // users/{userId}
  if (!userRef) return false;

  const userSnap = await userRef.get();
  const user = userSnap.data();
  if (!user || !user.fcm_token) {
    logger.info(
        `Skip reminder subscription untuk ${userRef.id} (tanpa fcm_token)`,
    );
    return false;
  }

  await admin.messaging().send({
    token: user.fcm_token,
    notification: {title, body},
    data: {
      type: "subscription_renewal",
      subscriptionId: subscriptionSnap.id,
      ...extraData,
    },
  });
  return true;
}

exports.sendSubscriptionRenewalReminders = onSchedule(
    {schedule: "every day 08:00", timeZone: "Asia/Jakarta"},
    async () => {
      const now = admin.firestore.Timestamp.now();

      const subsSnap = await admin
          .firestore()
          .collectionGroup("subscriptions")
          .where("status", "in", ["active", "trialing"])
          .get();

      let h3Sent = 0;
      let h1Sent = 0;
      let skippedNoPeriodEnd = 0;

      for (const doc of subsSnap.docs) {
        const sub = doc.data();
        const periodEnd = sub.current_period_end;

        if (!periodEnd) {
          // Dokumen lama dari sebelum fix current_period_end di
          // stripe-webhook.js -- tidak ada dasar buat hitung H-berapa.
          skippedNoPeriodEnd++;
          continue;
        }

        const msRemaining = periodEnd.toMillis() - now.toMillis();
        const daysRemaining = Math.ceil(msRemaining / (24 * 60 * 60 * 1000));

        if (!RENEWAL_REMINDER_DAYS_BEFORE.includes(daysRemaining)) continue;

        const dedupField = `reminder_h${daysRemaining}_sent_for_period_end`;
        const alreadySentForThisPeriod =
            sub[dedupField] && sub[dedupField].isEqual(periodEnd);
        if (alreadySentForThisPeriod) continue;

        const sent = await _sendSubscriptionReminderNotif(doc, {
          title: daysRemaining === 1 ?
            "Langganan berakhir besok" :
            `Langganan berakhir dalam ${daysRemaining} hari`,
          body: daysRemaining === 1 ?
            "Pastikan metode pembayaranmu aktif supaya langganan " +
              "tidak terganggu." :
            `Perpanjangan otomatis akan diproses dalam ${daysRemaining} ` +
              "hari. Pastikan metode pembayaranmu aktif.",
          extraData: {daysRemaining: String(daysRemaining)},
        });

        if (sent) {
          await doc.ref.update({[dedupField]: periodEnd});
          if (daysRemaining === 3) h3Sent++;
          if (daysRemaining === 1) h1Sent++;
        }
      }

      logger.info(
          `Reminder subscription: ${h3Sent} H-3, ${h1Sent} H-1 terkirim, ` +
          `${skippedNoPeriodEnd} dilewati (tidak ada current_period_end)`,
      );
    },
);

/**
 * CONTOH #4 -- notifikasi trigger ("Chat dan CS").
 *
 * CATATAN PENTING: aku cek ke seluruh codebase dan BELUM ada fitur chat
 * sama sekali (tidak ada model/collection chat/message). Jadi function
 * di bawah ini SCAFFOLD berdasarkan asumsi skema, bukan yang final:
 *
 *   users/{userId}/support_messages/{messageId}
 *   { sender: "cs" | "user", text: "...", created_at: <timestamp> }
 *
 * Kalau nanti fitur chat-nya dibuat dengan struktur beda (mis. nested di
 * bawah order, atau pakai koleksi top-level `chats/{chatId}/messages`),
 * tinggal ganti path trigger-nya di argumen pertama `onDocumentCreated`
 * dan nama field `sender`-nya -- logic notifikasinya (cek notif_prefs,
 * kirim FCM) tetap sama.
 */
exports.onSupportMessageCreated = onDocumentCreated(
    "users/{userId}/support_messages/{messageId}",
    async (event) => {
      const message = event.data.data();
      // Cuma notif kalau ini balasan DARI CS ke user, bukan pesan user sendiri.
      if (message.sender !== "cs") return;

      const userId = event.params.userId;
      const userSnap = await admin.firestore()
          .collection("users").doc(userId).get();
      const user = userSnap.data();
      if (!user) return;

      const wantsNotif = user.notif_prefs?.chat_cs !== false;
      if (!wantsNotif || !user.fcm_token) {
        logger.info(`Skip notif chat_cs untuk ${userId} (off/tanpa token)`);
        return;
      }

      await admin.messaging().send({
        token: user.fcm_token,
        notification: {
          title: "Balasan dari Customer Service",
          body: message.text ?? "Kamu punya pesan baru dari CS.",
        },
        data: {
          type: "chat_cs",
          messageId: event.params.messageId,
        },
      });
    },
);