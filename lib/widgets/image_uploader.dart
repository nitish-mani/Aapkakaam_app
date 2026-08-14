// this file is made responsive.

import 'dart:convert';
import 'dart:io';
// import 'dart:typed_data';
import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/models/data_model.dart';
import 'package:app_aapkakaam/widgets/banner_ad_widget.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImageUploader extends StatefulWidget {
  const ImageUploader({super.key});

  @override
  State<ImageUploader> createState() => _ImageUploaderState();
}

class _ImageUploaderState extends State<ImageUploader> {
  File? selectedFile;
  double uploadProgress = 0;
  bool imgLoading = false;
  String error = '';
  String success = '';
  late String token;
  final String category = isVendor.value ? 'vendor' : 'user';
  late String userId;
  final String serverUrl = KConstantURL.url;

  UserModel? user;
  VendorModel? vendor;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await getUserData();
    await getVendorData();
  }

  Future<void> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString("user");
    if (userData != null) {
      setState(() {
        user = UserModel.fromJson(jsonDecode(userData));
        token = 'Bearer ${user!.token}';
        userId = user!.userId;
      });
    }
  }

  Future<void> getVendorData() async {
    final prefs = await SharedPreferences.getInstance();
    final vendorData = prefs.getString("vendor");
    if (vendorData != null) {
      setState(() {
        vendor = VendorModel.fromJson(jsonDecode(vendorData));
        token = 'Bearer ${vendor!.token}';
        userId = vendor!.vendorId;
      });
    }
  }

  Future<File> _dataUrlToFile(String dataUrl, String filename) async {
    final splitData = dataUrl.split(',');
    final base64Str = splitData[1];
    final bytes = base64Decode(base64Str);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    return await file.writeAsBytes(bytes);
  }

  Future<void> _handleFileChange() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final file = File(picked.path);

      final resizedBytes = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        quality: 70,
        minHeight: 300,
        minWidth: 300,
        format: CompressFormat.jpeg,
      );

      if (resizedBytes != null) {
        final base64String = base64Encode(resizedBytes);
        final dataUrl = 'data:image/jpeg;base64,$base64String';
        final fileFromBase64 = await _dataUrlToFile(
          dataUrl,
          path.basename(picked.path),
        );
        setState(() {
          selectedFile = fileFromBase64;
        });
      }
    }
  }

  Future<void> _downloadAndSaveImage(String imageUrl, String fileName) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) throw Exception('Image download failed');

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';

      if (savedImagePath.value.isNotEmpty) {
        final oldFile = File(savedImagePath.value);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      }

      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      if (await file.exists()) {
        savedImagePath.value = filePath;
      }
    } catch (e) {
      debugPrint('❌ Failed to save image: $e');
    }
  }

  Future<void> _uploadToS3() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      _showError("You are offline");
      return;
    }

    if (selectedFile == null || imgLoading) {
      _showError(imgLoading ? "Uploading..." : "Please select image");
      return;
    }

    try {
      setState(() {
        imgLoading = true;
        uploadProgress = 0;
      });

      final presignResponse = await http.put(
        Uri.parse('$serverUrl/$category/uploads/$category/$userId'),
        headers: {'Authorization': token},
      );

      if (presignResponse.statusCode != 200) {
        throw Exception("Presign request failed");
      }

      final uploadUrl = jsonDecode(presignResponse.body)['urlForUploads'];

      final fileBytes = selectedFile!.readAsBytesSync();
      final uploadRequest =
          http.Request("PUT", Uri.parse(uploadUrl))
            ..headers['Content-Type'] = 'multipart/form-data'
            ..bodyBytes = fileBytes;

      final uploadResponse = await uploadRequest.send();

      if (uploadResponse.statusCode == 200) {
        final imageUrlResponse = await http.get(
          Uri.parse('$serverUrl/$category/getUploads/$category/$userId'),
          headers: {'Authorization': token},
        );

        if (imageUrlResponse.statusCode == 200) {
          final result = jsonDecode(imageUrlResponse.body);
          await _downloadAndSaveImage(
            result['imgURL'],
            '${DateTime.now().millisecondsSinceEpoch}.jpg',
          );

          final prefs = await SharedPreferences.getInstance();
          final vendorJson = prefs.getString('vendor');
          final userJson = prefs.getString('user');

          if (userJson != null) {
            final currentUser = UserModel.fromJson(jsonDecode(userJson));
            _updateUserProfile(currentUser, result);
          }

          if (vendorJson != null) {
            final currentVendor = VendorModel.fromJson(jsonDecode(vendorJson));
            _updateVendorProfile(currentVendor, result);
          }

          setState(() {
            imgLoading = false;
            success = "Image uploaded successfully";
          });

          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() => success = '');
              Navigator.pop(context, true);
            }
          });
        } else {
          throw Exception("Image URL fetch failed");
        }
      } else {
        throw Exception("Upload to S3 failed");
      }
    } catch (e) {
      if (mounted) {
        setState(() => imgLoading = false);
        _showError("Error uploading image");
      }
    }
  }

  void _showError(String msg) {
    if (mounted) {
      setState(() => error = msg);
      Future.delayed(
        const Duration(seconds: 3),
        () => mounted ? setState(() => error = '') : null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final bgColor = !isDark ? Colors.amber : Colors.teal;
    final screenWidth = MediaQuery.of(context).size.width;
    final avatarRadius = screenWidth * 0.2; // Responsive avatar size

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Upload Image',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.06, // Responsive font size
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (error.isNotEmpty)
                _StatusMessage(
                  message: error,
                  color: Colors.red,
                  width: screenWidth,
                ),
              if (success.isNotEmpty)
                _StatusMessage(
                  message: success,
                  color: Colors.green,
                  width: screenWidth,
                ),

              SizedBox(height: screenWidth * 0.05),
              CircleAvatar(
                radius: avatarRadius,
                backgroundImage:
                    selectedFile != null ? FileImage(selectedFile!) : null,
                child:
                    selectedFile == null
                        ? Icon(Icons.person, size: avatarRadius)
                        : null,
              ),
              SizedBox(height: screenWidth * 0.05),
              _ActionButton(
                onPressed: _handleFileChange,
                label: "Choose File",
                width: screenWidth * 0.6,
              ),
              if (uploadProgress > 0) ...[
                SizedBox(height: screenWidth * 0.03),
                LinearProgressIndicator(value: uploadProgress / 100),
                SizedBox(height: screenWidth * 0.02),
                Text(
                  "${uploadProgress.toStringAsFixed(0)}%",
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              SizedBox(height: screenWidth * 0.05),
              _ActionButton(
                onPressed: _uploadToS3,
                label: "Upload Image",
                width: screenWidth * 0.6,
                isLoading: imgLoading,
              ),
              SizedBox(height: screenWidth * 0.05),

              Center(child: BannerAdWidget()),
            ],
          ),
        ),
      ),
    );
  }

  void _updateVendorProfile(
    VendorModel vendor,
    Map<String, dynamic> responseJson,
  ) async {
    final updatedImgUrl = responseJson['imgURL'];
    final updatedVendor = VendorModel(
      token: vendor.token,
      vendorId: vendor.vendorId,
      name: vendor.name,
      email: vendor.email,
      verifyEmail: vendor.verifyEmail,
      phoneNo: vendor.phoneNo,
      verifyPhoneNo: vendor.verifyPhoneNo,
      type: vendor.type,
      gender: vendor.gender,
      rating: vendor.rating,
      ratingCount: vendor.ratingCount,
      wageRate: vendor.wageRate,
      address: vendor.address,
      balance: vendor.balance,
      wageRateType: vendor.wageRateType,
      imgURL: updatedImgUrl,
      message: responseJson['message'] ?? vendor.message,
    );

    final prefs = await SharedPreferences.getInstance();
    prefs.setString('vendor', jsonEncode(updatedVendor.toJson()));
  }

  void _updateUserProfile(
    UserModel user,
    Map<String, dynamic> responseJson,
  ) async {
    final updatedImgUrl = responseJson['imgURL'];
    final updatedUser = UserModel(
      token: user.token,
      userId: user.userId,
      name: user.name,
      email: user.email,
      verifyEmail: user.verifyEmail,
      phoneNo: user.phoneNo,
      verifyPhoneNo: user.verifyPhoneNo,
      gender: user.gender,
      address: user.address,
      balance: user.balance,
      imgURL: updatedImgUrl,
      message: responseJson['message'] ?? user.message,
    );

    final prefs = await SharedPreferences.getInstance();
    prefs.setString('user', jsonEncode(updatedUser.toJson()));
  }
}

class _StatusMessage extends StatelessWidget {
  final String message;
  final Color color;
  final double width;

  const _StatusMessage({
    required this.message,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width * 0.9,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.all(width * 0.03),
      margin: EdgeInsets.only(bottom: width * 0.03),
      child: Text(
        message,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: width * 0.035,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final double width;
  final bool isLoading;

  const _ActionButton({
    required this.onPressed,
    required this.label,
    required this.width,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: width * 0.04),
        ),
        child:
            isLoading
                ? SizedBox(
                  width: width * 0.06,
                  height: width * 0.06,
                  child: const CircularProgressIndicator(),
                )
                : Text(label, style: TextStyle(fontSize: width * 0.06)),
      ),
    );
  }
}
