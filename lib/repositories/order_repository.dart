    import 'package:cloud_firestore/cloud_firestore.dart';

    class OrderRepository {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final String userId; // Diambil dari Firebase Auth user yang sedang login

    OrderRepository({required this.userId});

    // Jalur pintas ke sub-koleksi order milik user tertentu sesuai aturan firestore.rules
    CollectionReference get _ordersRef =>
        _firestore.collection('users').doc(userId).collection('orders');

    // LOGIKA BACKEND: Bikin Nomor Nota Otomatis di Sisi Client (Substitusi Cloud Functions)
    String _generateOrderNumber(String laundryCode, int sequenceCount) {
        final dateStr = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '');
        final paddedSequence = (sequenceCount + 1).toString().padLeft(4, '0');
        return '$laundryCode-$dateStr-$paddedSequence'; // Hasil: JKT-20260703-0001
    }

    // FUNGSI UNTUK MENYIMPAN ORDER BARU
    Future<void> createOrder(Map<String, dynamic> orderData, String laundryCode) async {
        // 1. Hitung jumlah orderan hari ini untuk menentukan nomor urut nota
        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day).toIso8601String();
        
        final queryToday = await _ordersRef
            .where('createdAt', isGreaterThanOrEqualTo: todayStart)
            .get();
        
        // 2. Generate nomor nota otomatis
        final orderNumber = _generateOrderNumber(laundryCode, queryToday.docs.length);

        // 3. Masukkan nomor nota dan hitungan harga otomatis ke dalam data pesanan
        orderData['orderNumber'] = orderNumber;
        orderData['totalHarga'] = orderData['beratKg'] * 8000; // Contoh tarif Rp 8.000/kg
        orderData['status'] = 'Antre';
        orderData['createdAt'] = DateTime.now().toIso8601String();

        // 4. Tembak langsung ke Firestore database
        await _ordersRef.add(orderData);
    }
    }