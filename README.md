# 가림 패치 앱  
**산학협력 프로젝트 | Flutter 개발**  

## 📌 프로젝트 개요  
안과 환자의 가림 치료를 돕는 앱 서비스로, BLE 센서를 활용하여 실시간 데이터를 수집하고 사용자 맞춤형 알림을 제공합니다.  

## 🔹 기술 스택  
- **Flutter**  
- **State Management**: GetX  
- **Database**: SQLite (sqflite)  
- **Bluetooth**: flutter_blue_plus  
- **Server Communication**: http  
- **Push Notification**: flutter_local_notification  

## 🔹 구현 내용
- **BLE 센서 연동**: `flutter_blue_plus`를 사용한 센서 데이터 수집  
- **데이터 저장 및 관리**: `sqflite`를 활용한 내부 DB 구축  
- **전역 상태 관리**: `get`을 이용한 상태 관리  
- **서버와의 통신**: `http`를 활용한 데이터 전송  
- **푸시 알림**: `flutter_local_notification`을 이용하여 패치 착용 독려 알림 전송  
- **UI/UX 디자인**

## 📎 자료  
- 📄 [아이패치 앱 사진 및 설명](https://github.com/page1597/eyepatch_app/files/14524152/default.pdf)  
- 📝 [프로젝트 개발 기록](https://velog.io/@page1597/series/eyepatchapp)  
