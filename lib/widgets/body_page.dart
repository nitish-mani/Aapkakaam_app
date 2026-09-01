// this file is made responsive for all devices using flutter_screenutil
// Modern Premium UI Design with Emojis - Complete Service Data

import 'dart:convert';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/models/data_model.dart';
import 'package:app_aapkakaam/widgets/booking_date_selection.dart';
import 'package:app_aapkakaam/widgets/address_page.dart';
import 'package:app_aapkakaam/widgets/wage_rate_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Service Data Structure with Emojis
class ServiceItem {
  final String title;
  final String hindi;
  final String emoji;
  final String jobType;
  final String description;
  final String descriptionHindi;

  ServiceItem({
    required this.title,
    required this.hindi,
    required this.emoji,
    required this.jobType,
    required this.description,
    required this.descriptionHindi,
  });

  Map<String, String> toMap() {
    return {
      'title': title,
      'hindi': hindi,
      'emoji': emoji,
      'jobType': jobType,
      'description': description,
      'descriptionHindi': descriptionHindi,
    };
  }
}

class ServiceCategory {
  final String heading;
  final String headingHindi;
  final String icon;
  final List<ServiceItem> services;

  ServiceCategory({
    required this.heading,
    required this.headingHindi,
    required this.icon,
    required this.services,
  });
}

// ============================================================
// Complete Service Data with Emojis & Descriptions
// ============================================================
final List<ServiceCategory> serviceData = [
  // =========================================================
  // CONSTRUCTION & WORK
  // =========================================================
  ServiceCategory(
    heading: "Construction & Work",
    headingHindi: "निर्माण कार्य",
    icon: "🏗️",
    services: [
      ServiceItem(
        title: "Labour",
        hindi: "मजदूर",
        emoji: "👷",
        jobType: "labour",
        description:
            "Reliable labour for construction, loading, shifting and general work.",
        descriptionHindi:
            "घर, दुकान, निर्माण स्थल, सामान उठाने-रखने और दूसरे मेहनत के काम के लिए भरोसेमंद मजदूर खोजें।",
      ),
      ServiceItem(
        title: "Mason",
        hindi: "राजमिस्त्री",
        emoji: "🧱",
        jobType: "mason",
        description:
            "Book a mason for brickwork, walls, plastering and house construction.",
        descriptionHindi:
            "ईंट की चिनाई, दीवार, प्लास्टर और मकान बनाने के काम के लिए राजमिस्त्री बुक करें।",
      ),
      ServiceItem(
        title: "Contractor",
        hindi: "ठेकेदार / कॉन्ट्रैक्टर",
        emoji: "👷‍♂️",
        jobType: "contractor",
        description:
            "Find a contractor for complete construction and renovation work.",
        descriptionHindi:
            "निर्माण और रेनोवेशन के काम के लिए भरोसेमंद ठेकेदार खोजें।",
      ),
      ServiceItem(
        title: "Architect",
        hindi: "वास्तुकार / आर्किटेक्ट",
        emoji: "📐",
        jobType: "architect",
        description:
            "Find an architect for house planning, design and construction guidance.",
        descriptionHindi:
            "मकान की योजना, डिजाइन और निर्माण संबंधी सलाह के लिए आर्किटेक्ट खोजें।",
      ),
      ServiceItem(
        title: "Interior Designer",
        hindi: "इंटीरियर डिजाइनर",
        emoji: "🛋️",
        jobType: "interior designer",
        description:
            "Find an interior designer for home, shop and office interiors.",
        descriptionHindi:
            "घर, दुकान और ऑफिस के इंटीरियर डिजाइन के लिए इंटीरियर डिजाइनर खोजें।",
      ),
      ServiceItem(
        title: "Excavation Worker",
        hindi: "खुदाई मजदूर",
        emoji: "⛏️",
        jobType: "excavation worker",
        description:
            "Book workers for digging, excavation and site preparation.",
        descriptionHindi:
            "खुदाई और निर्माण स्थल तैयार करने के लिए मजदूर बुक करें।",
      ),
      ServiceItem(
        title: "Tiles Fitter",
        hindi: "टाइल मिस्त्री",
        emoji: "🔲",
        jobType: "tiles fitter",
        description:
            "Book tile fitting for floors, walls, kitchens and bathrooms.",
        descriptionHindi:
            "फर्श, दीवार, किचन और बाथरूम में टाइल लगाने के लिए टाइल मिस्त्री बुक करें।",
      ),
      ServiceItem(
        title: "Marble Fitter",
        hindi: "मार्बल मिस्त्री",
        emoji: "💎",
        jobType: "marble fitter",
        description:
            "Get marble fitting for floors, stairs, kitchens and other surfaces.",
        descriptionHindi:
            "फर्श, सीढ़ी, किचन और घर की दूसरी जगहों पर मार्बल लगवाने के लिए मिस्त्री खोजें।",
      ),
      ServiceItem(
        title: "Shuttering",
        hindi: "शटरिंग बुकिंग",
        emoji: "🏛️",
        jobType: "shuttering",
        description:
            "Book shuttering support for roofs, slabs and construction work.",
        descriptionHindi:
            "छत, स्लैब और निर्माण कार्य के लिए शटरिंग लगाने की सेवा बुक करें।",
      ),
      ServiceItem(
        title: "Welder",
        hindi: "वेल्डर",
        emoji: "🔥",
        jobType: "welder",
        description:
            "Find a welder for gates, grills, railings, frames and metal work.",
        descriptionHindi:
            "गेट, ग्रिल, रेलिंग, फ्रेम और लोहे की वेल्डिंग के काम के लिए वेल्डर बुलाएँ।",
      ),
      ServiceItem(
        title: "Fabricator",
        hindi: "फैब्रिकेटर",
        emoji: "⚙️",
        jobType: "fabricator",
        description:
            "Get custom metal fabrication for gates, grills, sheds and railings.",
        descriptionHindi:
            "गेट, ग्रिल, शेड, रेलिंग और लोहे के दूसरे स्ट्रक्चर बनवाने के लिए फैब्रिकेटर खोजें।",
      ),
      ServiceItem(
        title: "Glass Fitter",
        hindi: "ग्लास फिटर",
        emoji: "🪟",
        jobType: "glass fitter",
        description:
            "Book glass fitting for windows, doors, shops and partitions.",
        descriptionHindi:
            "खिड़की, दरवाजा, दुकान और पार्टिशन में कांच लगवाने के लिए ग्लास फिटर बुलाएँ।",
      ),
      ServiceItem(
        title: "Aluminium Fabricator",
        hindi: "एल्युमिनियम फैब्रिकेटर",
        emoji: "🔩",
        jobType: "aluminium fabricator",
        description:
            "Find an aluminium fabricator for doors, windows and frames.",
        descriptionHindi:
            "दरवाजे, खिड़की और फ्रेम के एल्युमिनियम काम के लिए फैब्रिकेटर खोजें।",
      ),
      ServiceItem(
        title: "Door & Window Repair",
        hindi: "दरवाजा और खिड़की मरम्मत",
        emoji: "🚪",
        jobType: "door window repair",
        description: "Get repair and fitting help for doors and windows.",
        descriptionHindi:
            "दरवाजे और खिड़की की मरम्मत और फिटिंग के लिए मिस्त्री बुलाएँ।",
      ),
      ServiceItem(
        title: "POP Worker",
        hindi: "पीओपी मिस्त्री",
        emoji: "🎭",
        jobType: "pop worker",
        description: "Get POP, ceiling design and decorative finishing work.",
        descriptionHindi:
            "घर या ऑफिस की POP, सीलिंग डिजाइन और सजावटी फिनिशिंग के लिए POP मिस्त्री बुक करें।",
      ),
    ],
  ),

  // =========================================================
  // HOME REPAIR & MAINTENANCE
  // =========================================================
  ServiceCategory(
    heading: "Home Repair & Maintenance",
    headingHindi: "गृह मरम्मत और रखरखाव",
    icon: "🛠️",
    services: [
      ServiceItem(
        title: "Electrician",
        hindi: "बिजली मिस्त्री",
        emoji: "⚡",
        jobType: "electrician",
        description:
            "Get help with wiring, fans, lights, switches and electrical problems.",
        descriptionHindi:
            "वायरिंग, पंखा, बल्ब, स्विच, बोर्ड और बिजली की खराबी ठीक करवाने के लिए बिजली मिस्त्री बुलाएँ।",
      ),
      ServiceItem(
        title: "Plumber",
        hindi: "प्लंबर",
        emoji: "🔧",
        jobType: "plumber",
        description:
            "Get plumbing help for taps, pipes, leaks, tanks and bathrooms.",
        descriptionHindi:
            "नल, पाइप, पानी की लीकेज, टंकी और बाथरूम के काम के लिए प्लंबर बुलाएँ।",
      ),
      ServiceItem(
        title: "Painter",
        hindi: "पेंटर",
        emoji: "🎨",
        jobType: "painter",
        description:
            "Book a painter for home, shop, room painting and finishing work.",
        descriptionHindi:
            "घर, कमरे या दुकान की पेंटिंग, रंग-रोगन और फिनिशिंग का काम करवाएँ।",
      ),
      ServiceItem(
        title: "Carpenter",
        hindi: "बढ़ई",
        emoji: "🪚",
        jobType: "carpenter",
        description:
            "Find a carpenter for doors, windows, furniture, cupboards and woodwork.",
        descriptionHindi:
            "दरवाजा, खिड़की, फर्नीचर, अलमारी और लकड़ी के काम के लिए बढ़ई बुलाएँ।",
      ),
    ],
  ),

  // =========================================================
  // APPLIANCE REPAIR
  // =========================================================
  ServiceCategory(
    heading: "Appliance Repair",
    headingHindi: "उपकरण मरम्मत",
    icon: "🔌",
    services: [
      ServiceItem(
        title: "AC Repair & Installation",
        hindi: "एसी मरम्मत और इंस्टॉलेशन",
        emoji: "❄️",
        jobType: "ac repair",
        description:
            "Book AC repair, installation, servicing and leakage support.",
        descriptionHindi:
            "AC की मरम्मत, इंस्टॉलेशन, सर्विस और लीकेज के लिए मिस्त्री बुलाएँ।",
      ),
      ServiceItem(
        title: "Refrigerator Repair",
        hindi: "फ्रिज मरम्मत",
        emoji: "🧊",
        jobType: "refrigerator repair",
        description:
            "Get help with refrigerator cooling, gas, electrical and common faults.",
        descriptionHindi:
            "फ्रिज की कूलिंग, गैस, बिजली और दूसरी खराबी ठीक करवाएँ।",
      ),
      ServiceItem(
        title: "Washing Machine Repair",
        hindi: "वॉशिंग मशीन मरम्मत",
        emoji: "🧺",
        jobType: "washing machine repair",
        description:
            "Find a technician for water, spinning and common washing-machine problems.",
        descriptionHindi:
            "वॉशिंग मशीन में पानी, स्पिन या दूसरी खराबी हो तो मिस्त्री बुलाएँ।",
      ),
      ServiceItem(
        title: "RO Service & Repair",
        hindi: "आरओ सर्विस और मरम्मत",
        emoji: "💧",
        jobType: "ro service",
        description: "Book RO servicing, filter replacement and repair.",
        descriptionHindi:
            "RO की सर्विस, फिल्टर बदलने और मरम्मत के लिए तकनीशियन बुलाएँ।",
      ),
      ServiceItem(
        title: "Geyser Repair",
        hindi: "गीजर मरम्मत",
        emoji: "🛁",
        jobType: "geyser repair",
        description: "Get help with geyser heating and common repair problems.",
        descriptionHindi:
            "गीजर गर्म नहीं कर रहा या खराब है तो गीजर मिस्त्री की सेवा लें।",
      ),
      ServiceItem(
        title: "Water Cooler Repair",
        hindi: "वॉटर कूलर मरम्मत",
        emoji: "🚰",
        jobType: "water cooler repair",
        description: "Find a technician for water cooler servicing and repair.",
        descriptionHindi:
            "वॉटर कूलर की सर्विस और मरम्मत के लिए तकनीशियन खोजें।",
      ),
      ServiceItem(
        title: "Chimney Repair & Cleaning",
        hindi: "चिमनी मरम्मत और सफाई",
        emoji: "🌬️",
        jobType: "chimney repair",
        description: "Book kitchen chimney repair, servicing and cleaning.",
        descriptionHindi: "किचन चिमनी की मरम्मत, सर्विस और सफाई करवाएँ।",
      ),
      ServiceItem(
        title: "Fan Repair & Installation",
        hindi: "पंखा मरम्मत और फिटिंग",
        emoji: "🌀",
        jobType: "fan repair",
        description: "Get fan repair, installation and fitting support.",
        descriptionHindi:
            "पंखे की मरम्मत, इंस्टॉलेशन और फिटिंग के लिए मिस्त्री बुलाएँ।",
      ),
      ServiceItem(
        title: "Mixer / Grinder Repair",
        hindi: "मिक्सर मरम्मत",
        emoji: "🥣",
        jobType: "mixer grinder repair",
        description: "Find a technician for mixer and grinder repair.",
        descriptionHindi: "मिक्सर और ग्राइंडर की मरम्मत के लिए तकनीशियन खोजें।",
      ),
      ServiceItem(
        title: "TV Repair",
        hindi: "टीवी मरम्मत",
        emoji: "📺",
        jobType: "tv repair",
        description:
            "Get help with TV power, display, sound and common problems.",
        descriptionHindi:
            "TV चालू नहीं हो रहा या स्क्रीन और साउंड में समस्या है तो मिस्त्री बुलाएँ।",
      ),
      ServiceItem(
        title: "Induction Repair",
        hindi: "इंडक्शन मरम्मत",
        emoji: "🍳",
        jobType: "induction repair",
        description: "Book induction cooktop repair and servicing.",
        descriptionHindi: "इंडक्शन की मरम्मत और सर्विस के लिए तकनीशियन बुलाएँ।",
      ),
      ServiceItem(
        title: "Inverter Repair & Service",
        hindi: "इन्वर्टर मरम्मत और सर्विस",
        emoji: "🔋",
        jobType: "inverter repair",
        description:
            "Get inverter and battery support for charging and backup problems.",
        descriptionHindi:
            "इन्वर्टर, बैटरी, चार्जिंग और बिजली बैकअप की खराबी ठीक करवाएँ।",
      ),
      ServiceItem(
        title: "CCTV Installation & Service",
        hindi: "सीसीटीवी स्थापना और सर्विस",
        emoji: "📹",
        jobType: "cctv installation",
        description:
            "Install and service CCTV cameras for homes, shops and offices.",
        descriptionHindi:
            "घर, दुकान या ऑफिस में CCTV कैमरा लगवाएँ और सर्विस करवाएँ।",
      ),
      ServiceItem(
        title: "Mobile Repair",
        hindi: "मोबाइल मरम्मत",
        emoji: "📱",
        jobType: "mobile repair",
        description:
            "Find a technician for mobile hardware and software problems.",
        descriptionHindi:
            "मोबाइल की हार्डवेयर और सॉफ्टवेयर खराबी ठीक करवाने के लिए तकनीशियन खोजें।",
      ),
      ServiceItem(
        title: "Laptop & PC Repair",
        hindi: "लैपटॉप और पीसी मरम्मत",
        emoji: "💻",
        jobType: "laptop pc repair",
        description: "Get laptop and PC hardware and software repair.",
        descriptionHindi:
            "लैपटॉप और पीसी की हार्डवेयर और सॉफ्टवेयर मरम्मत करवाएँ।",
      ),
      ServiceItem(
        title: "Generator Repair & Service",
        hindi: "जनरेटर मरम्मत और सर्विस",
        emoji: "⚡",
        jobType: "generator repair",
        description: "Book generator servicing, maintenance and repair.",
        descriptionHindi:
            "जनरेटर की सर्विस, मेंटेनेंस और मरम्मत के लिए तकनीशियन बुलाएँ।",
      ),
    ],
  ),

  // =========================================================
  // HOME SERVICES
  // =========================================================
  ServiceCategory(
    heading: "Home Services",
    headingHindi: "घरेलू सेवाएँ",
    icon: "🏡",
    services: [
      ServiceItem(
        title: "Cook",
        hindi: "रसोइया",
        emoji: "🍳",
        jobType: "cook",
        description: "Book a cook for home meals and everyday cooking.",
        descriptionHindi:
            "घर के खाने और रोजमर्रा की कुकिंग के लिए रसोइया बुक करें।",
      ),
      ServiceItem(
        title: "House Maid",
        hindi: "घरेलू सहायिका",
        emoji: "🧹",
        jobType: "house maid",
        description:
            "Find help for cleaning, dishes and everyday household work.",
        descriptionHindi:
            "घर की सफाई, बर्तन और रोजमर्रा के घरेलू काम के लिए घरेलू सहायिका खोजें।",
      ),
      ServiceItem(
        title: "Pest Control",
        hindi: "कीट नियंत्रण",
        emoji: "🐜",
        jobType: "pest control",
        description:
            "Book pest-control service for common household pests and termites.",
        descriptionHindi:
            "घर में कीड़े-मकौड़े और दीमक जैसी समस्या से छुटकारा पाने के लिए pest control करवाएँ।",
      ),
      ServiceItem(
        title: "Deep Cleaning",
        hindi: "गहरी सफाई",
        emoji: "🧽",
        jobType: "deep cleaning",
        description: "Get detailed deep cleaning for homes and spaces.",
        descriptionHindi:
            "घर की गहरी सफाई करवाकर धूल, गंदगी और जमा मैल साफ करवाएँ।",
      ),
      ServiceItem(
        title: "Water Tank Cleaning",
        hindi: "पानी की टंकी सफाई",
        emoji: "🪣",
        jobType: "water tank cleaning",
        description: "Book water-tank cleaning to remove dirt and buildup.",
        descriptionHindi: "घर की पानी की टंकी की गंदगी और जमा कचरा साफ करवाएँ।",
      ),
    ],
  ),

  // =========================================================
  // OFFICE SERVICES
  // =========================================================
  ServiceCategory(
    heading: "Office Services",
    headingHindi: "कार्यालय सेवा",
    icon: "🏢",
    services: [
      ServiceItem(
        title: "Office Boy & Pantry Help",
        hindi: "ऑफिस बॉय",
        emoji: "☕",
        jobType: "office boy",
        description:
            "Find office boy and pantry assistance for daily office work.",
        descriptionHindi:
            "ऑफिस के रोजमर्रा के काम और पैंट्री सहायता के लिए ऑफिस बॉय खोजें।",
      ),
      ServiceItem(
        title: "Office Deep Cleaning",
        hindi: "ऑफिस सफाई",
        emoji: "🧹",
        jobType: "office deep cleaning",
        description: "Book deep cleaning for offices and workplaces.",
        descriptionHindi: "ऑफिस और कार्यस्थल की गहरी सफाई करवाएँ।",
      ),
    ],
  ),

  // =========================================================
  // DAILY NEEDS
  // =========================================================
  ServiceCategory(
    heading: "Daily Needs",
    headingHindi: "दैनिक आवश्यकता",
    icon: "🏠",
    services: [
      ServiceItem(
        title: "Driver",
        hindi: "ड्राइवर",
        emoji: "🚕",
        jobType: "driver",
        description:
            "Find a driver for daily travel, office work, weddings and trips.",
        descriptionHindi:
            "घर, ऑफिस, शादी, यात्रा या रोजमर्रा के आने-जाने के लिए भरोसेमंद ड्राइवर खोजें।",
      ),
      ServiceItem(
        title: "Milk Man",
        hindi: "दूध वाला",
        emoji: "🥛",
        jobType: "milk man",
        description:
            "Connect with a local milk supplier for regular home delivery.",
        descriptionHindi:
            "घर तक रोजाना दूध पहुँचाने के लिए अपने आसपास के दूध वाले से संपर्क करें।",
      ),
      ServiceItem(
        title: "Washer Man",
        hindi: "धोबी",
        emoji: "👕",
        jobType: "washer man",
        description: "Find a washer man for washing and ironing clothes.",
        descriptionHindi:
            "कपड़े धोने और प्रेस करवाने के लिए अपने आसपास के धोबी की सेवा लें।",
      ),
      ServiceItem(
        title: "Gardener",
        hindi: "माली",
        emoji: "🌱",
        jobType: "gardener",
        description:
            "Book a gardener for plants, lawns, gardens and maintenance.",
        descriptionHindi:
            "घर, खेत या बगीचे की देखभाल और पौधों की देखरेख के लिए माली बुलाएँ।",
      ),
      ServiceItem(
        title: "Security Guard",
        hindi: "सुरक्षा गार्ड",
        emoji: "🛡️",
        jobType: "security guard",
        description:
            "Find security support for homes, shops, offices and events.",
        descriptionHindi:
            "घर, दुकान, ऑफिस, भवन या कार्यक्रम की सुरक्षा के लिए सिक्योरिटी गार्ड खोजें।",
      ),
      ServiceItem(
        title: "Baby Sitter",
        hindi: "बेबी सिटर",
        emoji: "👶",
        jobType: "baby sitter",
        description:
            "Find childcare support for families who need help looking after children.",
        descriptionHindi:
            "बच्चों की देखभाल के लिए अपने आसपास भरोसेमंद बेबी सिटर खोजें।",
      ),
      ServiceItem(
        title: "Old Age Caregiver",
        hindi: "बुजुर्ग देखभालकर्ता",
        emoji: "👴",
        jobType: "old age caregiver",
        description:
            "Find a caregiver for everyday elderly support and assistance.",
        descriptionHindi:
            "बुजुर्गों की रोजमर्रा की देखभाल और जरूरत की मदद के लिए केयरगिवर खोजें।",
      ),
    ],
  ),

  // =========================================================
  // EVENT & FUNCTION SERVICES
  // =========================================================
  ServiceCategory(
    heading: "Event & Function Services",
    headingHindi: "कार्यक्रम सेवा",
    icon: "🎉",
    services: [
      ServiceItem(
        title: "Photography",
        hindi: "फोटोग्राफी",
        emoji: "📸",
        jobType: "photography",
        description:
            "Book photography for weddings, parties and special events.",
        descriptionHindi:
            "शादी, पार्टी और खास कार्यक्रमों के लिए फोटोग्राफी बुक करें।",
      ),
      ServiceItem(
        title: "Videography",
        hindi: "वीडियोग्राफी",
        emoji: "🎥",
        jobType: "videography",
        description: "Book video coverage for weddings and special events.",
        descriptionHindi: "शादी और कार्यक्रम की वीडियो रिकॉर्डिंग करवाएँ।",
      ),
      ServiceItem(
        title: "DJ Service",
        hindi: "डीजे सर्विस",
        emoji: "🎧",
        jobType: "dj service",
        description:
            "Book DJ and sound services for weddings, parties and celebrations.",
        descriptionHindi:
            "शादी, पार्टी और समारोह के लिए DJ और साउंड सिस्टम बुक करें।",
      ),
      ServiceItem(
        title: "Music Artist",
        hindi: "म्यूज़िक आर्टिस्ट / गायक / वादक",
        emoji: "🎤",
        jobType: "music artist",
        description: "Find singers and musicians for events and celebrations.",
        descriptionHindi:
            "कार्यक्रम और समारोह के लिए गायक या संगीत कलाकार खोजें।",
      ),
      ServiceItem(
        title: "Decorator",
        hindi: "डेकोरेटर",
        emoji: "🎀",
        jobType: "decorator",
        description:
            "Book decoration services for weddings, parties and functions.",
        descriptionHindi:
            "शादी, पार्टी और कार्यक्रम की सजावट के लिए डेकोरेटर बुक करें।",
      ),
      ServiceItem(
        title: "Tent House Service",
        hindi: "टेंट हाउस सेवा",
        emoji: "⛺",
        jobType: "tent house",
        description:
            "Book tents, chairs, tables and event setup for functions.",
        descriptionHindi:
            "शादी, पार्टी और कार्यक्रम के लिए टेंट, कुर्सी, टेबल और जरूरी सामान बुक करें।",
      ),
      ServiceItem(
        title: "Catering Service",
        hindi: "कैटरिंग सेवा",
        emoji: "🍲",
        jobType: "catering service",
        description:
            "Book catering for weddings, parties, religious events and functions.",
        descriptionHindi:
            "शादी, पार्टी, धार्मिक कार्यक्रम और समारोह के लिए कैटरिंग व्यवस्था करवाएँ।",
      ),
      ServiceItem(
        title: "Mehandi Artist",
        hindi: "मेहंदी आर्टिस्ट",
        emoji: "🌸",
        jobType: "mehandi artist",
        description:
            "Find a mehndi artist for weddings, festivals and special occasions.",
        descriptionHindi:
            "शादी, त्योहार और खास मौकों के लिए मेहंदी आर्टिस्ट खोजें।",
      ),
      ServiceItem(
        title: "Makeup Artist",
        hindi: "मेकअप आर्टिस्ट",
        emoji: "💄",
        jobType: "makeup artist",
        description:
            "Book a professional makeup artist for weddings and occasions.",
        descriptionHindi:
            "शादी, पार्टी और खास मौकों के लिए प्रोफेशनल मेकअप आर्टिस्ट बुक करें।",
      ),
      ServiceItem(
        title: "Parlour",
        hindi: "पार्लर",
        emoji: "💇",
        jobType: "parlour",
        description:
            "Book beauty and parlour services for weddings and special occasions.",
        descriptionHindi:
            "शादी, त्योहार, पार्टी या खास मौके के लिए पार्लर और ब्यूटी सर्विस बुक करें।",
      ),
      ServiceItem(
        title: "Pandit Ji",
        hindi: "पंडित जी",
        emoji: "🕉️",
        jobType: "pandit ji",
        description:
            "Find a Pandit Ji for puja, griha pravesh, weddings and ceremonies.",
        descriptionHindi:
            "पूजा, गृह प्रवेश, शादी और धार्मिक कार्यक्रम के लिए पंडित जी बुक करें।",
      ),
      ServiceItem(
        title: "Lights",
        hindi: "लाइट बुकिंग",
        emoji: "💡",
        jobType: "lights",
        description:
            "Book decorative lighting for weddings, parties and events.",
        descriptionHindi:
            "शादी, पार्टी और कार्यक्रम के लिए सजावटी लाइटिंग की व्यवस्था करवाएँ।",
      ),
      ServiceItem(
        title: "Kirtan Mandali",
        hindi: "कीर्तन मंडली",
        emoji: "🎵",
        jobType: "kirtan mandli",
        description: "Find a kirtan and bhajan group for religious events.",
        descriptionHindi:
            "कीर्तन, भजन और धार्मिक कार्यक्रम के लिए कीर्तन मंडली बुक करें।",
      ),
      ServiceItem(
        title: "Waiter",
        hindi: "वेटर",
        emoji: "🍽️",
        jobType: "waiter",
        description:
            "Book waiters to serve guests at weddings, parties and events.",
        descriptionHindi:
            "शादी, पार्टी और कार्यक्रम में मेहमानों की सेवा के लिए वेटर बुक करें।",
      ),
      ServiceItem(
        title: "Chaat",
        hindi: "चाट",
        emoji: "🍛",
        jobType: "chaat",
        description:
            "Arrange chaat and street-food counters for parties and functions.",
        descriptionHindi:
            "शादी, पार्टी और कार्यक्रम के लिए चाट और स्ट्रीट फूड की व्यवस्था करें।",
      ),
      ServiceItem(
        title: "Dulha Rath",
        hindi: "दूल्हा रथ",
        emoji: "🐴",
        jobType: "dulha rath",
        description:
            "Book a decorated dulha rath for the groom's wedding procession.",
        descriptionHindi:
            "दूल्हे की बारात और शादी के लिए शानदार दूल्हा रथ बुक करें।",
      ),
      ServiceItem(
        title: "Paan Wala",
        hindi: "पान वाला",
        emoji: "🌿",
        jobType: "paan wala",
        description:
            "Arrange a paan counter or paan service for weddings and events.",
        descriptionHindi:
            "शादी और कार्यक्रम में मेहमानों के लिए पान की व्यवस्था करवाएँ।",
      ),
      ServiceItem(
        title: "Marriage Hall",
        hindi: "मैरिज हॉल",
        emoji: "💒",
        jobType: "marriage hall",
        description:
            "Find and book a suitable marriage hall for weddings and receptions.",
        descriptionHindi: "शादी, रिसेप्शन और कार्यक्रम के लिए मैरिज हॉल खोजें।",
      ),
      ServiceItem(
        title: "Band Party",
        hindi: "बैंड पार्टी",
        emoji: "🎺",
        jobType: "band party",
        description:
            "Book a band party for wedding processions and celebrations.",
        descriptionHindi:
            "बारात, शादी और खास कार्यक्रम के लिए बैंड पार्टी बुक करें।",
      ),
      ServiceItem(
        title: "Fireworks",
        hindi: "पटाखे",
        emoji: "🎆",
        jobType: "fireworks",
        description:
            "Find fireworks arrangements for suitable celebrations and events.",
        descriptionHindi:
            "शादी और खास कार्यक्रमों के लिए आतिशबाजी की व्यवस्था करें।",
      ),
      ServiceItem(
        title: "Fruits Seller",
        hindi: "फल विक्रेता",
        emoji: "🍎",
        jobType: "fruit seller",
        description:
            "Find a local fruit seller for fresh fruits for home and events.",
        descriptionHindi:
            "घर, दुकान या कार्यक्रम के लिए ताजे फल उपलब्ध करवाने वाला स्थानीय विक्रेता खोजें।",
      ),
    ],
  ),

  // =========================================================
  // TRANSPORTATION
  // =========================================================
  ServiceCategory(
    heading: "Transportation",
    headingHindi: "परिवहन सेवा",
    icon: "🚌",
    services: [
      ServiceItem(
        title: "Four Wheeler",
        hindi: "चार पहिया",
        emoji: "🚘",
        jobType: "four wheeler",
        description:
            "Book a four-wheeler for family travel, events and local trips.",
        descriptionHindi:
            "परिवार, यात्रा, शादी या जरूरी काम के लिए चार पहिया वाहन बुक करें।",
      ),
      ServiceItem(
        title: "Bus",
        hindi: "बस",
        emoji: "🚌",
        jobType: "bus",
        description:
            "Book a bus for weddings, school trips, group travel and events.",
        descriptionHindi:
            "शादी, स्कूल, यात्रा या ग्रुप ट्रिप के लिए बस बुक करें।",
      ),
      ServiceItem(
        title: "Auto",
        hindi: "ऑटो",
        emoji: "🛺",
        jobType: "auto",
        description:
            "Find an auto for local travel and everyday transportation.",
        descriptionHindi:
            "रोजमर्रा के आने-जाने और छोटी दूरी के लिए अपने आसपास ऑटो बुक करें।",
      ),
      ServiceItem(
        title: "E-Rikshaw",
        hindi: "ई-रिक्शा",
        emoji: "🛵",
        jobType: "e-rikshaw",
        description: "Book an e-rickshaw for short-distance local travel.",
        descriptionHindi:
            "छोटी दूरी और रोजमर्रा के आने-जाने के लिए ई-रिक्शा बुक करें।",
      ),
      ServiceItem(
        title: "Mini Truck",
        hindi: "मिनी ट्रक",
        emoji: "🚚",
        jobType: "mini truck",
        description: "Book a mini truck for furniture, goods and small loads.",
        descriptionHindi:
            "सामान, फर्नीचर और छोटे माल की ढुलाई के लिए मिनी ट्रक बुक करें।",
      ),
    ],
  ),

  // =========================================================
  // RURAL SERVICES
  // =========================================================
  ServiceCategory(
    heading: "Rural Services",
    headingHindi: "ग्रामीण सेवाएँ",
    icon: "🌾",
    services: [
      ServiceItem(
        title: "Dhankutti",
        hindi: "धान कुट्टी",
        emoji: "🌾",
        jobType: "dhankutti",
        description:
            "Find a local dhankutti service for rice and grain processing.",
        descriptionHindi:
            "धान कुटवाने और अनाज से जुड़े काम के लिए धान कुट्टी की सेवा खोजें।",
      ),
      ServiceItem(
        title: "Aata Chakki",
        hindi: "आटा चक्की",
        emoji: "🔄",
        jobType: "aata chakki",
        description:
            "Find a local flour mill for grinding wheat and other grains.",
        descriptionHindi:
            "गेहूं और दूसरे अनाज की पिसाई के लिए नजदीकी आटा चक्की खोजें।",
      ),
      ServiceItem(
        title: "Latrine Tank Cleaner",
        hindi: "शौचालय टैंक सफाई",
        emoji: "🧹",
        jobType: "latrine tank cleaner",
        description: "Book cleaning support for septic and toilet tanks.",
        descriptionHindi:
            "शौचालय या सेप्टिक टैंक की सफाई के लिए सफाई कर्मचारी बुलाएँ।",
      ),
      ServiceItem(
        title: "Pual Cutter",
        hindi: "पुआल कटर",
        emoji: "✂️",
        jobType: "pual cutter",
        description:
            "Find a pual cutter for cutting straw and preparing animal feed.",
        descriptionHindi:
            "पुआल काटने और पशुओं के चारे की तैयारी के लिए पुआल कटर बुक करें।",
      ),
      ServiceItem(
        title: "Bhoonsa Pual Seller",
        hindi: "भूसा विक्रेता",
        emoji: "🌿",
        jobType: "bhoonsa pual seller",
        description:
            "Find a local supplier for bhoonsa and pual used as animal feed.",
        descriptionHindi:
            "पशुओं के चारे के लिए भूसा और पुआल खरीदने हेतु स्थानीय विक्रेता खोजें।",
      ),
    ],
  ),

  // =========================================================
  // EDUCATION & COACHING
  // =========================================================
  ServiceCategory(
    heading: "Education & Coaching",
    headingHindi: "शिक्षा सेवाएँ",
    icon: "📚",
    services: [
      ServiceItem(
        title: "Home Tutor",
        hindi: "होम ट्यूटर",
        emoji: "📚",
        jobType: "home tutor",
        description:
            "Find a home tutor for school subjects, homework and exam preparation.",
        descriptionHindi:
            "बच्चों की पढ़ाई, होमवर्क और परीक्षा की तैयारी के लिए घर पर ट्यूटर खोजें।",
      ),
      ServiceItem(
        title: "Computer Trainer",
        hindi: "कंप्यूटर प्रशिक्षक",
        emoji: "💻",
        jobType: "computer trainer",
        description: "Find a computer trainer for practical computer learning.",
        descriptionHindi:
            "कंप्यूटर सीखने के लिए घर या आसपास कंप्यूटर ट्रेनर खोजें।",
      ),
      ServiceItem(
        title: "Music Teacher",
        hindi: "संगीत शिक्षक",
        emoji: "🎵",
        jobType: "music teacher",
        description:
            "Find a music teacher for singing and music-learning sessions.",
        descriptionHindi: "गायन और संगीत सीखने के लिए संगीत शिक्षक खोजें।",
      ),
      ServiceItem(
        title: "Dance Teacher",
        hindi: "नृत्य शिक्षक",
        emoji: "💃",
        jobType: "dance teacher",
        description:
            "Find a dance teacher for children, beginners and regular practice.",
        descriptionHindi: "डांस सीखने और नियमित अभ्यास के लिए डांस टीचर खोजें।",
      ),
      ServiceItem(
        title: "Art Teacher",
        hindi: "कला शिक्षक",
        emoji: "🎨",
        jobType: "art teacher",
        description:
            "Find an art teacher for drawing, painting and creative learning.",
        descriptionHindi:
            "चित्रकला, ड्राइंग और कला सीखने के लिए आर्ट टीचर खोजें।",
      ),
      ServiceItem(
        title: "Language Trainer",
        hindi: "भाषा प्रशिक्षक",
        emoji: "🗣️",
        jobType: "language trainer",
        description:
            "Find a language trainer for learning and practising a new language.",
        descriptionHindi:
            "नई भाषा सीखने और बोलने का अभ्यास करने के लिए भाषा ट्रेनर खोजें।",
      ),
    ],
  ),
];

// ============================================================
// MODERN PREMIUM BODY UI
// ============================================================

class BodyPage extends StatefulWidget {
  const BodyPage({super.key});

  @override
  State<BodyPage> createState() => _BodyPageState();
}

class _BodyPageState extends State<BodyPage>
    with AutomaticKeepAliveClientMixin {
  UserModel? user;
  VendorModel? vendor;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  int _selectedCategory = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    loadUserData();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.trim().toLowerCase();
          if (_searchQuery.isNotEmpty) {
            _selectedCategory = 0;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final vendorData = prefs.getString('vendor');

    if (!mounted) return;

    setState(() {
      if (userData != null) {
        user = UserModel.fromJson(jsonDecode(userData));
        isAddressAvailable.value = user?.address.isNotEmpty == true;
      }

      if (vendorData != null) {
        vendor = VendorModel.fromJson(jsonDecode(vendorData));

        // ✅ FIX: Check if any wage rate is set in the list
        isWageRateAvailable.value =
            vendor?.wageRate.any((rate) => rate != null && rate > 0) ?? false;

        isAddressAvailable.value = vendor?.address.isNotEmpty == true;
      }
    });
  }

  int get _totalServices =>
      serviceData.fold(0, (sum, category) => sum + category.services.length);

  List<ServiceCategory> get _visibleCategories {
    if (_searchQuery.isNotEmpty) {
      return serviceData
          .map(
            (category) => ServiceCategory(
              heading: isHindi ? category.headingHindi : category.heading,
              headingHindi: category.headingHindi,
              icon: category.icon,
              services:
                  category.services.where((service) {
                    final searchable =
                        [
                          isHindi ? service.hindi : service.title,
                          isHindi ? service.hindi : service.title,
                          service.jobType,
                          isHindi
                              ? service.descriptionHindi
                              : service.description,
                          isHindi
                              ? service.descriptionHindi
                              : service.description,
                        ].join(' ').toLowerCase();

                    return searchable.contains(_searchQuery);
                  }).toList(),
            ),
          )
          .where((category) => category.services.isNotEmpty)
          .toList();
    }

    return serviceData;
  }

  List<ServiceItem> get _selectedServices {
    if (_searchQuery.isNotEmpty) {
      return _visibleCategories.expand((e) => e.services).toList();
    }

    if (_selectedCategory <= 0) {
      return [];
    }

    return serviceData[_selectedCategory - 1].services;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return MultiNotifierBuilder(
      notifiers: [
        isDarkThemeNotifier,
        isAddressAvailable,
        isWageRateAvailable,
        isVendor,
        isHindiNotifier,
      ],
      builder: (context, values, child) {
        final isDarkTheme = values[0] as bool;
        final isAddress = values[1] as bool;
        final isWageRate = values[2] as bool;
        final vendorMode = values[3] as bool;
        final isHindi = values[4] as bool;

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final primaryColor = colorScheme.primary;
        final primaryContainer = colorScheme.primaryContainer;
        final surface = colorScheme.surface;
        final background = colorScheme.background;
        final onSurface = colorScheme.onSurface;

        return ColoredBox(
          color:
              isDarkTheme ? const Color(0xFF0B1020) : const Color(0xFFF7F9FC),
          child: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: primaryColor,
              onRefresh: loadUserData,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  if (!isAddress || (vendorMode && !isWageRate))
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 0),
                      sliver: SliverToBoxAdapter(
                        child: _buildWarningCards(
                          vendorMode,
                          isWageRate,
                          isAddress,
                          isDarkTheme,
                          primaryColor,
                        ),
                      ),
                    ),

                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 0),
                    sliver: SliverToBoxAdapter(
                      child: _buildCategoryChips(
                        isDarkTheme,
                        primaryColor,
                        onSurface,
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 20.h),
                    sliver: _buildServiceContent(
                      isDarkTheme,
                      primaryColor,
                      primaryContainer,
                      surface,
                      onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // Language Helper
  // ============================================================

  String _t(String hindi, String english) {
    return isHindiNotifier.value ? hindi : english;
  }

  // Current language. This is available to all helper/build methods.
  bool get isHindi => isHindiNotifier.value;

  // ============================================================
  // Category Chips
  // ============================================================

  Widget _buildCategoryChips(
    bool isDarkTheme,
    Color primaryColor,
    Color onSurface,
  ) {
    final chipBackground = isDarkTheme ? const Color(0xFF151B2D) : Colors.white;
    final textColor = isDarkTheme ? Colors.white : onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _searchQuery.isNotEmpty
                  ? (isHindi ? 'खोज परिणाम' : 'Search Results')
                  : (isHindi ? 'सेवाएँ देखें' : 'Explore Services'),
              style: TextStyle(
                color: textColor,
                fontSize: 17.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            if (_searchQuery.isEmpty)
              Text(
                isHindi ? 'स्वाइप →' : 'Swipe →',
                style: TextStyle(
                  color: isDarkTheme ? Colors.white38 : Colors.grey[500],
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        SizedBox(height: 9.h),
        SizedBox(
          height: 43.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: serviceData.length + 1,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (context, index) {
              final selected =
                  _searchQuery.isEmpty && _selectedCategory == index;

              if (index == 0) {
                return _categoryChip(
                  icon: '✨',
                  label: isHindi ? 'सभी' : 'All',
                  selected: selected,
                  isDarkTheme: isDarkTheme,
                  background: chipBackground,
                  primaryColor: primaryColor,
                  onTap: () {
                    setState(() => _selectedCategory = 0);
                  },
                );
              }

              final category = serviceData[index - 1];

              return _categoryChip(
                icon: category.icon,
                label: isHindi ? category.headingHindi : category.heading,
                selected: selected,
                isDarkTheme: isDarkTheme,
                background: chipBackground,
                primaryColor: primaryColor,
                onTap: () {
                  setState(() {
                    _selectedCategory = index;
                    _searchController.clear();
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _categoryChip({
    required String icon,
    required String label,
    required bool selected,
    required bool isDarkTheme,
    required Color background,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: EdgeInsets.symmetric(horizontal: 13.w),
          decoration: BoxDecoration(
            color: selected ? primaryColor : background,
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(
              color:
                  selected
                      ? primaryColor
                      : (isDarkTheme
                          ? Colors.white.withOpacity(0.07)
                          : const Color(0xFFE5EAF2)),
            ),
            boxShadow:
                selected
                    ? [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.18),
                        blurRadius: 12.r,
                        offset: Offset(0, 4.h),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            children: [
              Text(icon, style: TextStyle(fontSize: 16.sp)),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  color:
                      selected
                          ? Colors.white
                          : (isDarkTheme
                              ? Colors.white70
                              : const Color(0xFF505A6E)),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Content
  // ============================================================

  Widget _buildServiceContent(
    bool isDarkTheme,
    Color primaryColor,
    Color primaryContainer,
    Color surface,
    Color onSurface,
  ) {
    if (_searchQuery.isNotEmpty) {
      final results =
          _visibleCategories.expand((category) => category.services).toList();

      if (results.isEmpty) {
        return SliverToBoxAdapter(
          child: _buildEmptySearch(isDarkTheme, primaryColor, onSurface),
        );
      }

      return SliverList(
        delegate: SliverChildListDelegate([
          _buildSearchResultSummary(
            results.length,
            isDarkTheme,
            primaryColor,
            onSurface,
          ),
          SizedBox(height: 10.h),
          _buildResponsiveGrid(
            results,
            isDarkTheme,
            0,
            primaryColor,
            primaryContainer,
            surface,
            onSurface,
          ),
        ]),
      );
    }

    if (_selectedCategory > 0) {
      final category = serviceData[_selectedCategory - 1];

      return SliverList(
        delegate: SliverChildListDelegate([
          _buildCategoryTitle(
            category,
            isDarkTheme,
            primaryColor,
            primaryContainer,
            onSurface,
            showAd: true,
          ),
          SizedBox(height: 10.h),
          _buildResponsiveGrid(
            category.services,
            isDarkTheme,
            _selectedCategory,
            primaryColor,
            primaryContainer,
            surface,
            onSurface,
          ),
        ]),
      );
    }

    final widgets = <Widget>[];

    for (var index = 0; index < serviceData.length; index++) {
      final category = serviceData[index];

      widgets.add(
        _buildCategoryTitle(
          category,
          isDarkTheme,
          primaryColor,
          primaryContainer,
          onSurface,
          showAd: false,
        ),
      );
      widgets.add(SizedBox(height: 10.h));
      widgets.add(
        _buildResponsiveGrid(
          category.services,
          isDarkTheme,
          index,
          primaryColor,
          primaryContainer,
          surface,
          onSurface,
        ),
      );
      widgets.add(SizedBox(height: 20.h));
    }

    return SliverList(delegate: SliverChildListDelegate(widgets));
  }

  Widget _buildSearchResultSummary(
    int count,
    bool isDarkTheme,
    Color primaryColor,
    Color onSurface,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(isDarkTheme ? 0.13 : 0.07),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: primaryColor.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: primaryColor,
              size: 17.sp,
            ),
          ),
          SizedBox(width: 9.w),
          Expanded(
            child: Text(
              isHindi
                  ? '$count ${count == 1 ? 'सेवा मिली' : 'सेवाएँ मिलीं'}'
                  : '$count ${count == 1 ? 'service' : 'services'} found',
              style: TextStyle(
                color: isDarkTheme ? Colors.white : onSurface,
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearch(
    bool isDarkTheme,
    Color primaryColor,
    Color onSurface,
  ) {
    return Container(
      margin: EdgeInsets.only(top: 18.h),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 35.h),
      decoration: BoxDecoration(
        color: isDarkTheme ? const Color(0xFF151B2D) : Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color:
              isDarkTheme
                  ? Colors.white.withOpacity(0.06)
                  : const Color(0xFFE8ECF3),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72.w,
            height: 72.w,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text('🔎', style: TextStyle(fontSize: 32.sp))),
          ),
          SizedBox(height: 13.h),
          Text(
            isHindi ? 'सेवा नहीं मिली' : 'Service not found',
            style: TextStyle(
              color: isDarkTheme ? Colors.white : onSurface,
              fontSize: 17.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            isHindi
                ? 'दूसरा नाम लिखकर खोजें या अंग्रेज़ी में खोजें।'
                : 'Try another name or search in Hindi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDarkTheme ? Colors.white54 : Colors.grey[600],
              fontSize: 11.5.sp,
              height: 1.4,
            ),
          ),
          SizedBox(height: 14.h),
          OutlinedButton.icon(
            onPressed: _searchController.clear,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(isHindi ? 'खोज साफ़ करें' : 'Clear Search'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: BorderSide(color: primaryColor.withOpacity(0.35)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTitle(
    ServiceCategory category,
    bool isDarkTheme,
    Color primaryColor,
    Color primaryContainer,
    Color onSurface, {
    bool showAd = false,
  }) {
    return Container(
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: isDarkTheme ? const Color(0xFF151B2D) : Colors.white,
        borderRadius: BorderRadius.circular(19.r),
        border: Border.all(
          color:
              isDarkTheme
                  ? Colors.white.withOpacity(0.06)
                  : const Color(0xFFE8ECF3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 47.w,
            height: 47.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.90)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15.r),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.18),
                  blurRadius: 12.r,
                  offset: Offset(0, 5.h),
                ),
              ],
            ),
            child: Center(
              child: Text(category.icon, style: TextStyle(fontSize: 23.sp)),
            ),
          ),
          SizedBox(width: 11.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHindi ? category.headingHindi : category.heading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white : onSurface,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  !isHindi ? category.headingHindi : category.heading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        isDarkTheme ? Colors.white54 : const Color(0xFF7B8497),
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 7.h),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(isDarkTheme ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(11.r),
            ),
            child: Column(
              children: [
                Text(
                  '${category.services.length}',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  isHindi ? 'सेवाएँ' : 'services',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white38 : Colors.grey[500],
                    fontSize: 7.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Responsive Grid
  // ============================================================

  Widget _buildResponsiveGrid(
    List<ServiceItem> services,
    bool isDarkTheme,
    int seed,
    Color primaryColor,
    Color primaryContainer,
    Color surface,
    Color onSurface,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final crossAxisCount =
            width >= 1100
                ? 5
                : width >= 800
                ? 4
                : width >= 560
                ? 3
                : 2;

        final itemWidth =
            (width - ((crossAxisCount - 1) * 9.w)) / crossAxisCount;

        // Build all items in a list
        List<Widget> items = [];

        // Add ad at the top

        // Add services with ads between them
        for (int i = 0; i < services.length; i++) {
          // Add service card
          items.add(
            SizedBox(
              width: itemWidth,
              child: _buildServiceCard(
                services[i],
                isDarkTheme,
                seed * 100 + i,
                primaryColor,
                primaryContainer,
                surface,
                onSurface,
              ),
            ),
          );

          // Add ad after every 6 services (but not after the last one)
        }

        return Wrap(spacing: 9.w, runSpacing: 9.h, children: items);
      },
    );
  }

  // ============================================================
  // Premium Service Card
  // ============================================================

  Widget _buildServiceCard(
    ServiceItem service,
    bool isDarkTheme,
    int index,
    Color primaryColor,
    Color primaryContainer,
    Color surface,
    Color onSurface,
  ) {
    final colors = _getEmojiColors(service.emoji);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 180 + ((index % 8) * 35)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10.h * (1 - value)),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showServiceDetail(service),
          borderRadius: BorderRadius.circular(19.r),
          splashColor: primaryColor.withOpacity(0.08),
          highlightColor: primaryColor.withOpacity(0.04),
          child: Ink(
            decoration: BoxDecoration(
              color: isDarkTheme ? const Color(0xFF151B2D) : surface,
              borderRadius: BorderRadius.circular(19.r),
              border: Border.all(
                color:
                    isDarkTheme
                        ? Colors.white.withOpacity(0.055)
                        : const Color(0xFFE8ECF3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkTheme ? 0.12 : 0.045),
                  blurRadius: 14.r,
                  offset: Offset(0, 6.h),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(9.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 58.w,
                        height: 58.w,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors:
                                isDarkTheme
                                    ? [
                                      colors[0].withOpacity(0.18),
                                      colors[1].withOpacity(0.10),
                                    ]
                                    : [
                                      colors[0].withOpacity(0.13),
                                      colors[1].withOpacity(0.07),
                                    ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors[0].withOpacity(0.10),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            service.emoji,
                            style: TextStyle(fontSize: 29.sp),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -2.w,
                        bottom: -1.h,
                        child: Container(
                          width: 18.w,
                          height: 18.w,
                          decoration: BoxDecoration(
                            color:
                                isDarkTheme
                                    ? const Color(0xFF151B2D)
                                    : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            margin: EdgeInsets.all(3.w),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 9.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    isHindi ? service.hindi : service.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDarkTheme ? Colors.white : onSurface,
                      fontSize: 11.5.sp,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    isHindi ? service.title : service.hindi,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          isDarkTheme
                              ? Colors.white54
                              : const Color(0xFF8992A3),
                      fontSize: 9.5.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Warning Cards
  // ============================================================

  Widget _buildWarningCards(
    bool isVendor,
    bool isWageRate,
    bool isAddress,
    bool isDarkTheme,
    Color primaryColor,
  ) {
    final warnings = <Map<String, String>>[];

    if (isVendor) {
      if (!isWageRate) {
        warnings.add({
          'icon': '💰',
          'title':
              isHindiNotifier.value
                  ? 'सेवा शुल्क अपडेट करें'
                  : 'Add Service Charge',
          'subtitle':
              isHindiNotifier.value
                  ? 'प्रोफ़ाइल की बेहतर जानकारी के लिए अपनी सेवा शुल्क अपडेट करें।'
                  : 'Add your Service Charge to improve profile visibility.',
          'action': 'serviceCharge',
        });
      }

      if (!isAddress) {
        warnings.add({
          'icon': '📍',
          'title': isHindiNotifier.value ? 'पता जोड़ें' : 'Add Address',
          'subtitle':
              isHindiNotifier.value
                  ? 'पास के ग्राहकों को दिखने के लिए अपना सेवा स्थान जोड़ें।'
                  : 'Add your service location to become visible nearby.',
          'action': 'address',
        });
      }
    } else if (!isAddress) {
      warnings.add({
        'icon': '📍',
        'title': isHindiNotifier.value ? 'पता आवश्यक है' : 'Address Required',
        'subtitle':
            isHindiNotifier.value
                ? 'पास की सेवाएँ खोजने के लिए अपना पता जोड़ें।'
                : 'Add your address to discover nearby services.',
        'action': 'address',
      });
    }

    return Column(
      children:
          warnings.map((warning) {
            return GestureDetector(
              onTap: () {
                switch (warning['action']) {
                  case 'serviceCharge':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WageRatePage(),
                      ),
                    );
                    break;

                  case 'address':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddAddressDialog(),
                      ),
                    );
                    break;
                }
              },
              child: Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(17.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF97316).withOpacity(0.18),
                      blurRadius: 14.r,
                      offset: Offset(0, 6.h),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42.w,
                      height: 42.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(13.r),
                      ),
                      child: Center(
                        child: Text(
                          warning['icon']!,
                          style: TextStyle(fontSize: 21.sp),
                        ),
                      ),
                    ),

                    SizedBox(width: 10.w),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            warning['title']!,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            warning['subtitle']!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.88),
                              fontSize: 9.5.sp,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white.withOpacity(0.85),
                      size: 23.sp,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }
  // ============================================================
  // Emoji Colors
  // ============================================================

  List<Color> _getEmojiColors(String emoji) {
    final map = {
      '👷': [const Color(0xFFFF6B35), const Color(0xFFF7931E)],
      '🧱': [const Color(0xFFE74C3C), const Color(0xFFC0392B)],
      '⚡': [const Color(0xFFFFD700), const Color(0xFFFFA500)],
      '🔧': [const Color(0xFF3498DB), const Color(0xFF2980B9)],
      '🎨': [const Color(0xFF9B59B6), const Color(0xFF8E44AD)],
      '🪚': [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
      '🔲': [const Color(0xFF95A5A6), const Color(0xFF7F8C8D)],
      '💎': [const Color(0xFF1ABC9C), const Color(0xFF16A085)],
      '🏛️': [const Color(0xFFF39C12), const Color(0xFFE67E22)],
      '🔥': [const Color(0xFFE74C3C), const Color(0xFFC0392B)],
      '⚙️': [const Color(0xFF95A5A6), const Color(0xFF7F8C8D)],
      '🪟': [const Color(0xFF3498DB), const Color(0xFF2980B9)],
      '🎭': [const Color(0xFF9B59B6), const Color(0xFF8E44AD)],
      '❄️': [const Color(0xFF3498DB), const Color(0xFF2980B9)],
      '🧊': [const Color(0xFF1ABC9C), const Color(0xFF16A085)],
      '🏍️': [const Color(0xFFE74C3C), const Color(0xFFC0392B)],
      '🚗': [const Color(0xFF3498DB), const Color(0xFF2980B9)],
      '💻': [const Color(0xFF2C3E50), const Color(0xFF34495E)],
      '📹': [const Color(0xFFE74C3C), const Color(0xFFC0392B)],
      '🔋': [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
      '📡': [const Color(0xFFF39C12), const Color(0xFFE67E22)],
      '🚕': [const Color(0xFFFFD700), const Color(0xFFFFA500)],
      '📚': [const Color(0xFF9B59B6), const Color(0xFF8E44AD)],
      '🥛': [const Color(0xFFECF0F1), const Color(0xFFBDC3C7)],
      '👕': [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
      '🌱': [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
      '🛡️': [const Color(0xFF3498DB), const Color(0xFF2980B9)],
      '🧹': [const Color(0xFF95A5A6), const Color(0xFF7F8C8D)],
      '👶': [const Color(0xFFFF6B81), const Color(0xFFFF4757)],
      '👴': [const Color(0xFF8B4513), const Color(0xFFA0522D)],
      '💄': [const Color(0xFFE74C3C), const Color(0xFFC0392B)],
      '🌸': [const Color(0xFFFF6B81), const Color(0xFFFF4757)],
      '🕉️': [const Color(0xFFFF6B35), const Color(0xFFF7931E)],
      '🍳': [const Color(0xFFFFD700), const Color(0xFFFFA500)],
      '💡': [const Color(0xFFFFD700), const Color(0xFFFFA500)],
      '⛺': [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
      '🎵': [const Color(0xFF9B59B6), const Color(0xFF8E44AD)],
      '🎧': [const Color(0xFF2C3E50), const Color(0xFF34495E)],
      '🍽️': [const Color(0xFFE74C3C), const Color(0xFFC0392B)],
      '💧': [const Color(0xFF3498DB), const Color(0xFF2980B9)],
      '🍛': [const Color(0xFFFF6B35), const Color(0xFFF7931E)],
      '🐴': [const Color(0xFF8B4513), const Color(0xFFA0522D)],
      '🌿': [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
      '🍎': [const Color(0xFFE74C3C), const Color(0xFFC0392B)],
      '💒': [const Color(0xFFFF6B81), const Color(0xFFFF4757)],
      '📸': [const Color(0xFF2C3E50), const Color(0xFF34495E)],
      '🎥': [const Color(0xFFE74C3C), const Color(0xFFC0392B)],
      '💋': [const Color(0xFFFF6B81), const Color(0xFFFF4757)],
      '🎺': [const Color(0xFFFFD700), const Color(0xFFFFA500)],
      '🎆': [const Color(0xFFFF6B35), const Color(0xFFF7931E)],
      '🍲': [const Color(0xFFFFD700), const Color(0xFFFFA500)],
      '🚘': [const Color(0xFF3498DB), const Color(0xFF2980B9)],
      '🚌': [const Color(0xFFFFD700), const Color(0xFFFFA500)],
      '🛺': [const Color(0xFFFF6B35), const Color(0xFFF7931E)],
      '🛵': [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
      '🚚': [const Color(0xFFE74C3C), const Color(0xFFC0392B)],
      '🌾': [const Color(0xFFF39C12), const Color(0xFFE67E22)],
      '🔄': [const Color(0xFF3498DB), const Color(0xFF2980B9)],
      '✂️': [const Color(0xFFE74C3C), const Color(0xFFC0392B)],
      '🐜': [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
      '🧽': [const Color(0xFF3498DB), const Color(0xFF2980B9)],
      '🪣': [const Color(0xFF95A5A6), const Color(0xFF7F8C8D)],
      '🛁': [const Color(0xFF3498DB), const Color(0xFF2980B9)],
      '🧺': [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
      '📺': [const Color(0xFF2C3E50), const Color(0xFF34495E)],
      '💃': [const Color(0xFFFF6B81), const Color(0xFFFF4757)],
      '🗣️': [const Color(0xFF9B59B6), const Color(0xFF8E44AD)],
    };
    return map[emoji] ?? [const Color(0xFF2563EB), const Color(0xFF1D4ED8)];
  }

  // ============================================================
  // Service Detail Bottom Sheet
  // ============================================================

  void _showServiceDetail(ServiceItem service) {
    final isDark = isDarkThemeNotifier.value;
    final isHindi = isHindiNotifier.value;
    final profession = service.title;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    // final primaryContainer = colorScheme.primaryContainer;
    final surface = colorScheme.surface;
    final onSurface = colorScheme.onSurface;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (sheetContext) {
        final colors = _getEmojiColors(service.emoji);

        return DraggableScrollableSheet(
          initialChildSize: 0.80,
          minChildSize: 0.42,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            final background = isDark ? const Color(0xFF101626) : surface;
            final titleColor = isDark ? Colors.white : onSurface;
            final secondary = isDark ? Colors.white60 : const Color(0xFF70798B);

            return Container(
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.20),
                    blurRadius: 30.r,
                    offset: Offset(0, -8.h),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 25.h),
                child: Column(
                  children: [
                    Container(
                      width: 42.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color:
                            isDark ? Colors.white24 : const Color(0xFFD7DCE5),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    SizedBox(height: 19.h),

                    // Hero service icon
                    Container(
                      width: 94.w,
                      height: 94.w,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colors[0].withOpacity(0.16),
                            colors[1].withOpacity(0.08),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors[0].withOpacity(0.14),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          service.emoji,
                          style: TextStyle(fontSize: 49.sp),
                        ),
                      ),
                    ),

                    SizedBox(height: 14.h),

                    Text(
                      isHindi ? service.hindi : service.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 23.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      isHindi ? service.hindi : service.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: secondary,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    SizedBox(height: 14.h),

                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.09),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.work_outline_rounded,
                            color: primaryColor,
                            size: 16.sp,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            service.jobType,
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 18.h),

                    _detailInfoCard(
                      title:
                          isHindi
                              ? 'इस सेवा के बारे में'
                              : 'About this service',
                      icon: Icons.info_outline_rounded,
                      isDark: isDark,
                      primaryColor: primaryColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isHindi
                                ? service.descriptionHindi
                                : service.description,
                            style: TextStyle(
                              color:
                                  isDark
                                      ? Colors.white70
                                      : const Color(0xFF596376),
                              fontSize: 12.5.sp,
                              height: 1.55,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Container(
                            height: 1,
                            color:
                                isDark
                                    ? Colors.white.withOpacity(0.06)
                                    : const Color(0xFFE8ECF3),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 15.h),

                    Row(
                      children: [
                        Expanded(
                          child: _featureTile(
                            icon: Icons.location_on_outlined,
                            title: isHindi ? 'पास में' : 'Nearby',
                            subtitle:
                                isHindi ? 'स्थानीय सेवा' : 'Local service',
                            isDark: isDark,
                            primaryColor: primaryColor,
                          ),
                        ),
                        SizedBox(width: 9.w),
                        Expanded(
                          child: _featureTile(
                            icon: Icons.verified_outlined,
                            title: isHindi ? 'आसान' : 'Easy',
                            subtitle:
                                isHindi ? 'जल्दी बुकिंग' : 'Quick booking',
                            isDark: isDark,
                            primaryColor: primaryColor,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 18.h),

                    SizedBox(
                      width: double.infinity,
                      height: 54.h,
                      child: ElevatedButton(
                        onPressed:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => BookingDateSelection(
                                      profession: profession,
                                      hindiName: service.hindi,
                                    ),
                              ),
                            ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17.r),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('📅'),
                            SizedBox(width: 8.w),
                            Text(
                              isHindi ? 'अभी खोजें' : 'Search Now',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 5.w),
                            Icon(Icons.arrow_forward_rounded, size: 18.sp),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailInfoCard({
    required String title,
    required IconData icon,
    required bool isDark,
    required Color primaryColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151B2D) : const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE8ECF3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: primaryColor, size: 18.sp),
              ),
              SizedBox(width: 9.w),
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF172033),
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }

  Widget _featureTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required Color primaryColor,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151B2D) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE8ECF3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 35.w,
            height: 35.w,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.09),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryColor, size: 18.sp),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF273249),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.grey[500],
                    fontSize: 8.5.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MultiNotifierBuilder
// ============================================================

class MultiNotifierBuilder extends StatelessWidget {
  final List<ValueNotifier> notifiers;
  final Widget Function(BuildContext, List<dynamic>, Widget?) builder;
  final Widget? child;

  const MultiNotifierBuilder({
    super.key,
    required this.notifiers,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _buildNestedListeners(0, context, [], child);
  }

  Widget _buildNestedListeners(
    int index,
    BuildContext context,
    List<dynamic> values,
    Widget? child,
  ) {
    if (index >= notifiers.length) {
      return builder(context, values, child);
    }

    return ValueListenableBuilder(
      valueListenable: notifiers[index],
      builder: (context, value, _) {
        final newValues = List<dynamic>.from(values)..add(value);
        return _buildNestedListeners(index + 1, context, newValues, child);
      },
    );
  }
}
