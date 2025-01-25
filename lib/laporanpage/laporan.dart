import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Untuk mengatur content type

class LaporanPage extends StatefulWidget {
  @override
  _LaporanPageState createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _jenisController = TextEditingController();
  final TextEditingController _lokasiController = TextEditingController();
  final TextEditingController _tanggalController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _waController = TextEditingController(); // Controller untuk WA
  XFile? _pickedImage;
  bool _isFotoEmpty = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _pickedImage = image;
      _isFotoEmpty = image == null;
    });
  }

  // Fungsi untuk mengirim laporan ke backend Django
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Validasi foto
      if (_pickedImage == null) {
        setState(() {
          _isFotoEmpty = true;
        });
        return;
      }

      // URL endpoint API Django
      final url = Uri.parse('http://192.168.1.6:8001/api/laporan/create/');

      // Buat multipart request
      var request = http.MultipartRequest('POST', url);

      // Tambahkan field teks
      request.fields['nama_pelapor'] = _nameController.text;
      request.fields['jenis_bencana'] = _jenisController.text;
      request.fields['lokasi_kejadian'] = _lokasiController.text;
      request.fields['tanggal_kejadian'] = _tanggalController.text;
      request.fields['deskripsi'] = _deskripsiController.text;
      request.fields['nomor_wa'] = _waController.text; // Menambahkan nomor WA

      // Tambahkan file gambar
      var file = await http.MultipartFile.fromPath(
        'foto', // Nama field di backend Django
        _pickedImage!.path,
        contentType: MediaType('image', 'jpeg'), // Sesuaikan dengan tipe file
      );
      request.files.add(file);

      // Kirim request
      var response = await request.send();

      // Cek status response
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Laporan berhasil dikirim')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim laporan: ${response.statusCode}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Gambar dan teks penjelasan
              Column(
                children: [
                  Image.asset(
                    'assets/images/salingkabar.png',
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Laporkan Bencana, Selamatkan Nyawa!",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Pada halaman ini, kamu bisa melaporkan kejadian bencana alam yang terjadi di sekitarmu. "
                    "Laporanmu akan dibagikan ke pengguna lain untuk meningkatkan kewaspadaan dan membantu sesama. "
                    "Mari bersama-sama menjaga keselamatan dan keamanan lingkungan kita!",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              SizedBox(height: 24),
              // Form input
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Pelapor',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama pelapor wajib diisi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _jenisController,
                decoration: InputDecoration(
                  labelText: 'Jenis Bencana',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Jenis bencana wajib diisi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _lokasiController,
                decoration: InputDecoration(
                  labelText: 'Lokasi Kejadian',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lokasi kejadian wajib diisi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _tanggalController,
                decoration: InputDecoration(
                  labelText: 'Waktu dan Tanggal',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickedTime != null) {
                      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
                      String formattedTime = pickedTime.format(context);
                      setState(() {
                        _tanggalController.text = "$formattedDate $formattedTime";
                      });
                    }
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Waktu dan tanggal wajib diisi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              // Text area untuk deskripsi kejadian
              TextFormField(
                controller: _deskripsiController,
                decoration: InputDecoration(
                  labelText: 'Deskripsi Kejadian',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5, // Membuat text area lebih besar
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Deskripsi kejadian wajib diisi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              // Form input untuk nomor WhatsApp
              TextFormField(
                controller: _waController,
                decoration: InputDecoration(
                  labelText: 'Nomor WhatsApp',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nomor WhatsApp wajib diisi';
                  }
                  // Validasi nomor WA
                  if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                    return 'Nomor WA hanya boleh terdiri dari angka';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.camera_alt),
                label: Text('Unggah Foto'),
              ),
              if (_isFotoEmpty) // Tampilkan pesan error jika foto belum diunggah
                Text(
                  'Foto wajib diunggah',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              if (_pickedImage != null) ...[
                SizedBox(height: 8),
                Text('Foto berhasil dipilih'),
                SizedBox(height: 8),
                Image.file(
                  File(_pickedImage!.path),
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ],
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Kirim Laporan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
