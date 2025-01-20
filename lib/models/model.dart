class TransactionModel {
  final int idTransaksi;
  final int idUser;
  final int idTipe;
  final int idKategori;
  final int nominal;
  final String tanggalTransaksi;
  final String? deskripsi;
  final String? tanggalDihapus;

  TransactionModel({
    required this.idTransaksi,
    required this.idUser,
    required this.idTipe,
    required this.idKategori,
    required this.nominal,
    required this.tanggalTransaksi,
    this.deskripsi,
    this.tanggalDihapus,
  });

  // Fungsi untuk parsing dari JSON ke TransactionModel
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      idTransaksi: int.tryParse(json['id_transaksi'].toString()) ?? 0,
      idUser: int.tryParse(json['id_user'].toString()) ?? 0,
      idTipe: int.tryParse(json['id_tipe'].toString()) ?? 0,
      idKategori: int.tryParse(json['id_kategori'].toString()) ?? 0,
      nominal: int.tryParse(json['nominal'].toString()) ?? 0,
      tanggalTransaksi: json['tanggal_transaksi'] ?? '',
      deskripsi: json['deskripsi'],
      tanggalDihapus: json['tanggal_dihapus'],
    );
  }

  // Fungsi untuk mengonversi TransactionModel ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id_transaksi': idTransaksi,
      'id_user': idUser,
      'id_tipe': idTipe,
      'id_kategori': idKategori,
      'nominal': nominal,
      'tanggal_transaksi': tanggalTransaksi,
      'deskripsi': deskripsi,
      'tanggal_dihapus': tanggalDihapus,
    };
  }
}
