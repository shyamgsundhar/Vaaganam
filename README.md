# Vaaganam

## About the Project

Vaaganam is a comprehensive vehicle management and trip tracking system. The name "Vaaganam" is derived from Tamil, where "Vaa" means "Come" and "Ganam" means "Time," symbolizing the efficient and timely management of vehicles. The system is designed to streamline trip management, monitor vehicle usage, and provide real-time updates for drivers and administrators.

---

## System Design Summary

The system is designed with a modular architecture to ensure scalability and maintainability. Below is a high-level overview of the system design:

![System Design](system_design.png)

### Key Components:
1. **Frontend**: Built using Flutter, providing a seamless cross-platform experience for Android, iOS, Web, and Desktop users.
2. **Backend**: Firebase Firestore serves as the backend, offering real-time database capabilities and cloud functions for serverless operations.
3. **Authentication**: Firebase Authentication is used to manage user roles (drivers, admins) and secure access.
4. **Database**: Firestore is used to store trip details, driver profiles, vehicle statuses, and logs.
5. **Real-Time Updates**: Leveraging Firestore's real-time capabilities to provide instant updates on trip progress and vehicle statuses.

---

## Technology Stack

### Frontend:
- **Flutter**: For building a cross-platform application with a modern and responsive UI.
- **Dart**: The programming language used with Flutter.

### Backend:
- **Firebase Firestore**: A NoSQL cloud database for storing and syncing data in real-time.
- **Firebase Authentication**: For secure user authentication and role management.
- **Firebase Cloud Functions**: For serverless backend logic.

### Database:
- **Firestore**: Used to store collections such as `trips`, `drivers`, `vehicles`, and `logs`.

---

## Key Challenges Faced and Solutions

I have included the all the details and Issues faced mentioned in the below Google Sheets
(https://docs.google.com/spreadsheets/d/1QmmxJjxUrA-GdXvP05IlIY3GY5K0gCGOhNLbn4IZdtE/edit?usp=sharing)
---

## Lessons Learned

1. **Importance of Modular Design**:
   - A modular architecture simplifies development, testing, and scaling.

2. **Real-Time Database Benefits**:
   - Firestore's real-time capabilities significantly enhance user experience by providing instant updates.

3. **Cross-Platform Development**:
   - Flutter's ability to build for multiple platforms from a single codebase saved development time and effort.

4. **Role-Based Security**:
   - Implementing secure role-based access control is crucial for maintaining data integrity and user trust.

---

## How to Run the Project

1. Clone the repository:
   ```bash
   git clone https://github.com/shyamgsundhar/Vaaganam.git
   ```

2. Navigate to the project directory:
   ```bash
   cd Vaaganam
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app:
   ```bash
   flutter run
   ```

---

## Future Enhancements

1. **Advanced Analytics**:
   - Integrate analytics to provide insights into vehicle usage and trip efficiency.

2. **Push Notifications**:
   - Add Firebase Cloud Messaging for real-time notifications.

3. **Admin Dashboard**:
   - Develop a web-based admin dashboard for better management and reporting.

4. **Integration with IoT Devices**:
   - Connect with IoT devices for real-time vehicle tracking and diagnostics.

---

## Contributors

- **Shyam G Sundhar** - [GitHub](https://github.com/shyamgsundhar)

---
