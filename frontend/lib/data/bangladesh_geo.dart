// lib/data/bangladesh_geo.dart
// Static geographic data for Bangladesh: districts and their upazilas.

class BangladeshGeo {
  BangladeshGeo._();

  static const List<String> districts = [
    'Bagerhat', 'Bandarban', 'Barguna', 'Barishal', 'Bhola', 'Bogura',
    'Brahmanbaria', 'Chandpur', 'Chapai Nawabganj', 'Chattogram', 'Chuadanga',
    'Cox\'s Bazar', 'Cumilla', 'Dhaka', 'Dinajpur', 'Faridpur', 'Feni',
    'Gaibandha', 'Gazipur', 'Gopalganj', 'Habiganj', 'Jamalpur', 'Jashore',
    'Jhalokathi', 'Jhenaidah', 'Joypurhat', 'Khagrachhari', 'Khulna',
    'Kishoreganj', 'Kurigram', 'Kushtia', 'Lakshmipur', 'Lalmonirhat',
    'Madaripur', 'Magura', 'Manikganj', 'Meherpur', 'Moulvibazar',
    'Munshiganj', 'Mymensingh', 'Naogaon', 'Narail', 'Narayanganj',
    'Narsingdi', 'Natore', 'Netrokona', 'Nilphamari', 'Noakhali',
    'Pabna', 'Panchagarh', 'Patuakhali', 'Pirojpur', 'Rajbari', 'Rajshahi',
    'Rangamati', 'Rangpur', 'Satkhira', 'Shariatpur', 'Sherpur', 'Sirajganj',
    'Sunamganj', 'Sylhet', 'Tangail', 'Thakurgaon',
  ];

  /// Key upazilas per district. Add more entries as needed.
  static const Map<String, List<String>> upazilasByDistrict = {
    'Dhaka': [
      'Dhamrai', 'Dohar', 'Keraniganj', 'Nawabganj', 'Savar',
      'Dhaka Sadar (City Corporations)',
    ],
    'Gazipur': [
      'Gazipur Sadar', 'Kaliakair', 'Kaliganj', 'Kapasia', 'Sreepur',
    ],
    'Narayanganj': [
      'Araihazar', 'Bandar', 'Narayanganj Sadar', 'Rupganj', 'Sonargaon',
    ],
    'Chattogram': [
      'Anwara', 'Banshkhali', 'Boalkhali', 'Chandanaish', 'Fatikchhari',
      'Hathazari', 'Karnaphuli', 'Lohagara', 'Mirsharai', 'Patiya',
      'Rangunia', 'Raozan', 'Sandwip', 'Satkania', 'Sitakunda',
      'Chattogram Sadar (City Corporation)',
    ],
    'Cox\'s Bazar': [
      'Chakaria', 'Cox\'s Bazar Sadar', 'Kutubdia', 'Maheshkhali',
      'Pekua', 'Ramu', 'Teknaf', 'Ukhia',
    ],
    'Sylhet': [
      'Balaganj', 'Beanibazar', 'Bishwanath', 'Companiganj', 'Fenchuganj',
      'Golapganj', 'Gowainghat', 'Jaintiapur', 'Kanaighat', 'Osmani Nagar',
      'South Surma', 'Sylhet Sadar', 'Zakiganj',
    ],
    'Rajshahi': [
      'Bagha', 'Bagmara', 'Charghat', 'Durgapur', 'Godagari',
      'Mohanpur', 'Paba', 'Puthia', 'Tanore',
    ],
    'Khulna': [
      'Batiaghata', 'Dacope', 'Daulatpur', 'Dighalia', 'Dumuria',
      'Koyra', 'Paikgachha', 'Phultala', 'Rupsha', 'Terokhada',
      'Khulna Sadar (City Corporation)',
    ],
    'Barishal': [
      'Agailjhara', 'Babuganj', 'Bakerganj', 'Banaripara', 'Gaurnadi',
      'Hizla', 'Mehendiganj', 'Muladi', 'Wazirpur',
      'Barisal Sadar (City Corporation)',
    ],
    'Mymensingh': [
      'Bhaluka', 'Dhobaura', 'Fulbaria', 'Gaffargaon', 'Gauripur',
      'Haluaghat', 'Ishwarganj', 'Mymensingh Sadar', 'Nandail',
      'Phulpur', 'Trishal',
    ],
    'Rangpur': [
      'Badarganj', 'Gangachara', 'Kaunia', 'Mithapukur', 'Pirgachha',
      'Pirganj', 'Rangpur Sadar', 'Taraganj',
    ],
    'Cumilla': [
      'Barura', 'Brahmanpara', 'Burichang', 'Chandina', 'Chauddagram',
      'Daudkandi', 'Debidwar', 'Homna', 'Laksam', 'Lalmai',
      'Meghna', 'Monohorganj', 'Muradnagar', 'Nangalkot', 'Titas',
      'Cumilla Sadar', 'Cumilla Sadar South',
    ],
    'Bogura': [
      'Adamdighi', 'Bogura Sadar', 'Dhunat', 'Dupchanchia', 'Gabtali',
      'Kahaloo', 'Nandigram', 'Sariakandi', 'Shajahanpur', 'Sherpur',
      'Shibganj', 'Sonatala',
    ],
  };

  /// Returns upazilas for a district, or an empty list if not found.
  static List<String> upazilas(String district) =>
      upazilasByDistrict[district] ?? [];
}
