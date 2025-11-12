// import 'package:flutter/material.dart';

// class IdentifyRolePage extends StatelessWidget {
//   const IdentifyRolePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Select Role')),
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text(
//               'Choose your role to continue',
//               style: TextStyle(fontSize: 18),
//             ),
//             const SizedBox(height: 24),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton.icon(
//                 icon: const Icon(Icons.drive_eta),
//                 label: const Text('Driver'),
//                 onPressed: () => Navigator.of(context).pushNamed('/driver'),
//               ),
//             ),
//             const SizedBox(height: 12),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton.icon(
//                 icon: const Icon(Icons.local_shipping),
//                 label: const Text('Dispatcher'),
//                 onPressed: () => Navigator.of(context).pushNamed('/dispatcher'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
