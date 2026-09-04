// import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';

// class BannerAdWidget extends StatefulWidget {
//   final AdSize adSize;

//   const BannerAdWidget({super.key, this.adSize = AdSize.banner});

//   @override
//   State<BannerAdWidget> createState() => _BannerAdWidgetState();
// }

// class _BannerAdWidgetState extends State<BannerAdWidget> {
//   BannerAd? _bannerAd;
//   bool _isLoaded = false;
//   int _retryCount = 0;
//   final int _maxRetries = 3;

//   @override
//   void initState() {
//     super.initState();

//     // Ensure ad is loaded after first frame and a short delay
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       Future.delayed(const Duration(seconds: 1), () {
//         _loadAd();
//       });
//     });
//   }

//   void _loadAd() {
//     _bannerAd = BannerAd(
//       adUnitId: 'ca-app-pub-1204932742437478/9726477431',
//       size: widget.adSize,
//       request: const AdRequest(),
//       listener: BannerAdListener(
//         onAdLoaded: (_) {
//           setState(() {
//             _isLoaded = true;
//             _retryCount = 0; // reset retry on success
//           });
//         },
//         onAdFailedToLoad: (ad, error) {
//           ad.dispose();
//           debugPrint('BannerAd failed to load: $error');

//           if (_retryCount < _maxRetries) {
//             _retryCount++;
//             final delay = Duration(
//               seconds: 2 * _retryCount,
//             ); // Exponential backoff
//             Future.delayed(delay, _loadAd);
//           }
//         },
//       ),
//     )..load();
//   }

//   @override
//   void dispose() {
//     _bannerAd?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();
//     return SizedBox(
//       // width: _bannerAd!.size.width.toDouble(),
//       // height: _bannerAd!.size.height.toDouble(),
//       // child: AdWidget(ad: _bannerAd!),
//     );
//   }
// }
