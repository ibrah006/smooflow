# Smooflow

## An App designed for Advertising & Digital Printing Companies

A **custom-built Flutter application** designed for advertising and digital printing companies to streamline workflows, track staff performance, and minimize waste.  
The app focuses on **project management, team collaboration, and production monitoring**, ensuring projects stay on schedule while maximizing staff efficiency.  

---

## ✨ Key Features  

### 📊 Project & Workflow Management  
- Interactive project timelines showing each department’s progress  
- Track activity, status, and tasks for each project  
- Department stages: **Planning → Design → Production → Finishing → Application → Finished/Cancelled**  

### 🎨 Design Department  
- Supports artwork submission & modifications  
- Built-in client approval/rejection workflow  
- Mandatory artwork dimension tracking  
- Restart design cycle if client disapproves  

### 🖨️ Printing Department  
- Interactive **printer layout/map view** with drag-and-drop placement  
- Assign printers with nicknames and track assigned staff  
- Live progress indicators and task statuses  
- Alerts for errors, failures, or when a printer is stuck  

### 🔧 Finishing & Application  
- Simple finishing process (MVP stage)  
- Application staff can **clock in/out**, track dimensions of work completed  
- Site in-charge approves or rejects reported progress  

### 📈 Analytics & Performance  
- Admin dashboard with project progress overview  
- Highlights **top performers** per project  
- Detects efficiency vs. estimated effort (future AI support planned)  
- Warnings if deadlines are at risk or extended timelines are needed  

### ⚡ System & Maintenance  
- Notifications for device/component failures  
- Manager alerts for urgent attention or technical intervention  
- Built-in **Notification Center** & **Global Search**  

---

## Screenshots

### Admin Views
<table>
  <tr>
    <td><img src="assets/screenshots/admin_dashboard.png" width="250"/></td>
    <td><img src="assets/screenshots/admin_dashboard_2.png" width="250"/></td>
    <td><img src="assets/screenshots/admin_projects.png" width="250"/></td>
    <td><img src="assets/screenshots/admin_teams.png" width="250"/></td>
  </tr>
</table>

### Reports
<table>
  <tr>
    <td><img src="assets/screenshots/production_report_screen.gif" alt="Description" width="400"/></td>
    <td><img src="assets/screenshots/project_report_screen.gif" alt="Description" width="400"/></td>
  </tr>
</table>

### Project
<img src="assets/screenshots/project_details.png" alt="Description" width="250"/>

### Schedule Print Job
<img src="assets/screenshots/schedule_job_1.png" alt="Description" width="250"/>
<img src="assets/screenshots/schedule_job_2.png" alt="Description" width="250"/>
<img src="assets/screenshots/schedule_job_3.png" alt="Description" width="250"/>
<img src="assets/screenshots/schedule_job_4.png" alt="Description" width="250"/>

### Print Job
<img src="assets/screenshots/print_job_details.png" alt="Description" width="250"/>

<!-- <img src="assets/screenshots/dashboard.png" alt="Description" width="250"/> -->
### Material & Stock Management
<img src="assets/screenshots/material_stock.png" alt="Description" width="250"/>
<img src="assets/screenshots/material_transactions.png" alt="Description" width="250"/>
<img src="assets/screenshots/stock_in_info.png" alt="Description" width="250"/>
<!-- <img src="assets/screenshots/project_info.png" alt="Description" width="250"/>
<img src="assets/screenshots/task_info.png" alt="Description" width="250"/>
<img src="assets/screenshots/timline.png" alt="Description" width="250"/>
<img src="assets/screenshots/timeline_stage_info.png" alt="Description" width="250"/> -->

### Login And Auth
<img src="assets/screenshots/login.png" alt="Description" width="250"/>

## Create Installers

### Macos
Build release:
```bash
flutter build macos --release
```
Create DMG installer:
```bash
mkdir -p build/macos/Build/Products/Release/installer                                             

create-dmg \
  --volname "Smooflow" \
  --volicon "assets/icons/logo.png" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 128 \
  --icon "smooflow.app" 200 190 \
  --hide-extension "smooflow.app" \
  --app-drop-link 600 185 \
  "build/macos/Build/Products/Release/installer/Smooflow-1.0.dmg" \
  "build/macos/Build/Products/Release/smooflow.app"
```

---

## 🔒 License

This project is **proprietary / source-available**.

The source code is visible for evaluation purposes only.
Unauthorized use, redistribution, or commercial use is prohibited.

See the [LICENSE](./LICENSE) file for details.
