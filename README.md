# 📱 PolCare: Intelligent Lost & Found System

![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-02569B?logo=flutter&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.8%2B-3776AB?logo=python&logoColor=white)
![TensorFlow](https://img.shields.io/badge/TensorFlow-Lite-FF6F00?logo=tensorflow&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Supported-FFCA28?logo=firebase&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green)

**PolCare** is a cross-platform mobile application designed to modernize the **Lost & Found** ecosystem at **Politeknik Negeri Medan (Polmed)**. Unlike traditional text-based systems, PolCare leverages **Artificial Intelligence (Computer Vision)** to automate the item matching process based on visual similarity.

---

## 📸 Screenshots


| Login Screen | Dashboard | AI Search Result |
|:---:|:---:|:---:|
| <img src="screenshots/login.png" width="200"/> | <img src="screenshots/home.png" width="200"/> | <img src="screenshots/result.png" width="200"/> |

---

## 🌟 Key Features

### 🧠 AI-Powered Visual Search (The Core)
* **Deep Metric Learning:** Utilizes **MobileNetV2** (CNN) to extract visual features from uploaded images.
* **Auto-Matching:** Implements **Cosine Similarity** algorithms to compare lost item photos with the found item database in real-time.
* **Objectivity:** Eliminates the ambiguity of text descriptions (e.g., "Black Wallet") by relying on visual patterns.

### 📱 Functional Features (CRUD)
* **Report Lost Item:** Users can upload photos, location, and time of the lost item.
* **Report Found Item:** Finders can post items they found to help others.
* **Real-time Database:** Built on **Firebase Firestore** for instant data synchronization.
* **History Tracking:** Users can track the status of their reports (Active/Found/Claimed).
* **Authentication:** Secure login/register system for Polmed students/staff.

---

## 🛠 Tech Stack

The project follows a decoupled architecture separating the Mobile Frontend from the AI Processing Unit.

| Component | Technology | Description |
| :--- | :--- | :--- |
| **Mobile App** | **Flutter (Dart)** | Cross-platform UI (Android/iOS) with Clean Architecture. |
| **Backend API** | **Python (Flask)** | Microservice acting as the AI Gateway. |
| **AI Engine** | **TensorFlow / Keras** | **MobileNetV2** (Pre-trained on ImageNet) for Feature Extraction. |
| **Database** | **Firebase Firestore** | NoSQL Cloud Database for storing metadata. |
| **Storage** | **Firebase Storage** | Cloud storage for item images. |

---

## ⚙️ How It Works (AI Pipeline)

1.  **Input:** User uploads an image via the Flutter App.
2.  **Preprocessing:** The image is sent to the Python Flask Server, resized to `224x224`, and normalized.
3.  **Feature Extraction:** The image passes through the **MobileNetV2** model (headless). The model outputs a high-dimensional feature vector.
4.  **Similarity Calculation:** This vector is compared against all stored vectors in the database using **Cosine Similarity**.
5.  **Output:** The system returns a ranked list of items with the highest similarity scores (e.g., > 80% match).

---

## 🚀 Getting Started

Follow these steps to run the project locally.

### Prerequisites
* Flutter SDK installed.
* Python 3.8+ installed.
* Firebase Project setup (google-services.json).

### 1. Clone the Repository
```bash
git clone [https://github.com/username/polcare.git](https://github.com/username/polcare.git)
cd polcare

2. Setup Flutter App
flutter pub get
# Add your google-services.json to android/app/
flutter run

3. Setup AI Server (Python)
cd backend_ai
pip install -r requirements.txt
python app.py

📂 Project Structure
polcare/
├── android/            # Android Native config
├── ios/                # iOS Native config
├── lib/
│   ├── core/           # Constants, Utils, Theme
│   ├── data/           # Models, Repositories, Firebase Services
│   ├── presentation/   # UI: Pages, Widgets, Controllers
│   └── main.dart       # Entry point
├── backend_ai/         # Python Flask Scripts & Models
├── assets/             # Images & Fonts
└── pubspec.yaml        # Dependencies

📄 License
<center> Created with ❤️ by <b>Heykel Prayogi Timanta G</b>
Student ID: 2205181054 | Politeknik Negeri Medan </center>
