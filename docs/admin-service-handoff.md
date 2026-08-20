# Admin Service Handoff

เอกสารนี้สรุป backend contract ที่หน้า `AdminMainScreen` ใช้อยู่จริงในแอป Flutter ปัจจุบัน เพื่อให้ทีมเว็บ implement ต่อได้โดยไม่ต้องไล่ source เองทั้งหมด

## 1. ภาพรวม Service ที่หน้า Admin ต่ออยู่

- `Firebase Auth`
  ใช้สำหรับ admin login และโหลด session ปัจจุบัน
- `Cloud Firestore`
  ใช้เป็น source หลักของข้อมูล admin ทั้งหมด และใช้ realtime read ผ่าน `snapshots()`
- `Cloud Functions`
  ใช้ callable function สำหรับจัดการ user account
- `Firebase App Check`
  activate ตอน startup ก่อนเรียก Firebase service อื่น

ค่าที่สำคัญ:

- callable function region: `asia-southeast1`
- admin service instance ถูกสร้างใน `main.dart` ผ่าน `FirebaseAdminService(firestore, functions)`

## 2. Authentication / Authorization

### 2.1 Login และ profile ของ admin

- login ใช้ `FirebaseAuth`
- profile ของ user ทุก role อยู่ใน collection `app_users`
- record ใน `app_users` มี field สำคัญ:
  `name`, `role`, `referenceId`, `profilePhotoPath`, `email`, `createdAt`, `updatedAt`, `isArchived`, `archivedAt`

### 2.2 เงื่อนไขการเป็น admin

ฝั่ง callable function (`functions/index.js`) ใช้ `assertAdmin()` โดยอนุญาตเมื่ออย่างใดอย่างหนึ่งเป็นจริง:

- `request.auth.token.admin === true`
- หรือใน `app_users/{uid}` มี `role == 'admin'` และ `isArchived != true`

### 2.3 Firestore Rules ที่เกี่ยวกับ admin

- `schools`, `teachers`, `admins`: เขียนได้เฉพาะ admin
- `parents`, `drivers`, `buses`, `children`, `trips`: admin เขียนได้ทั้งหมด
- `admins` อ่านได้เฉพาะ admin
- admin read ข้อมูลส่วนใหญ่ได้ทั้งหมดเมื่อ signed in

หมายเหตุ:

- callable function ฝั่ง admin ตั้ง `enforceAppCheck: false`
- แต่ตัวแอปเปิด `FirebaseAppCheck.instance.activate(...)` ตอน startup อยู่แล้ว

## 3. Realtime Read ที่หน้า Admin ใช้จริง

ตอนเข้า `AdminMainScreen` จะเรียก `AdminProvider.bootstrap()` แล้ว subscribe Firestore แบบ realtime ทั้งหมดดังนี้:

- `schools` ผ่าน `watchSchools()`
- `parents` ผ่าน `watchParents()`
- `teachers` ผ่าน `watchTeachers()`
- `drivers` ผ่าน `watchDrivers()`
- `admins` ผ่าน `watchAdmins()`
- `children` ผ่าน `watchChildren()`
- `buses` ผ่าน `watchBuses()`
- `trips` ผ่าน `watchTrips()`

พฤติกรรมสำคัญ:

- mobile admin โหลดทุก collection มาทีเดียว แล้วค่อย filter ใน client
- `selectedSchoolId` ใช้ filter view ฝั่ง UI ไม่ได้เปลี่ยน query ฝั่ง Firestore ตอน bootstrap
- ทีมเว็บควรถือว่านี่คือ current behavior ไม่ใช่ข้อเสนอ refactor

## 4. UI-to-Service Matrix ตาม 5 Tab

### 4.1 Schools

| Flow | Read | Write path | Side effects / rules |
| --- | --- | --- | --- |
| List schools | `schools` | ไม่มี | sort ตาม `name` |
| Create school | `schools` | direct Firestore `saveSchool()` | สร้าง id แบบ `school_<token>` ถ้าไม่มี id |
| Edit school | `schools` | direct Firestore `saveSchool()` | merge กับ record เดิม และคงค่า archive เดิม |
| Archive / restore school | `schools`, `teachers`, `children`, `trips` | direct Firestore `setSchoolArchived()` | archive ได้ต่อเมื่อไม่มี active `teachers`, `children`, `open trips` |

field หลักที่ UI ส่งตอน create/edit:

- `id`
- `name`
- `address`
- `lat`
- `lng`
- `morningPickup`
- `morningDropoff`
- `eveningPickup`
- `eveningDropoff`

### 4.2 People

People tab แยกย่อยเป็น `Parents`, `Teachers`, `Drivers`

| Flow | Read | Write path | Side effects / rules |
| --- | --- | --- | --- |
| List parents | `parents` | ไม่มี | UI filter ตาม `selectedSchoolId` จาก `parent.schoolIds` |
| List teachers | `teachers` | ไม่มี | UI filter ตาม `teacher.schoolId` |
| List drivers | `drivers`, `buses` | ไม่มี | แสดงชื่อรถจาก `driver.busId` |
| Create parent / teacher / driver | `schools`, `buses` บางกรณี | callable `manageUser` with `action=create` | สร้าง Firebase Auth user, เขียน role doc, เขียน `app_users` |
| Edit parent / teacher / driver | `schools`, `buses` บางกรณี | callable `manageUser` with `action=update` | update Auth user และ role doc ที่ผูกกับ `referenceId` |
| Archive / restore parent / teacher / driver | related collections ตาม role | callable `manageUser` with `action=archive` / `restore` | disable/enable Auth user และ update `isArchived` ใน role doc + `app_users` |

payload ที่ Flutter ส่งเข้า `manageUser`:

- `uid`
- `referenceId`
- `role`
- `name`
- `email`
- `phone`
- `licenseNumber`
- `password`
- `busId`
- `schoolId`
- เพิ่ม `action` ตอนเรียก function

business rules สำคัญ:

- `teacher` ต้องมี `schoolId`
- `password` ต้องยาวอย่างน้อย 6 ตัวอักษรเมื่อส่งมา
- `driver` สามารถผูกรถผ่าน `busId`
- archive `parent` ไม่ได้ถ้ายังมี active children
- archive `driver` ไม่ได้ถ้ายังผูกกับ active bus
- ถ้า role เป็น `admin` function จะ set custom claim `{ admin: true }` ตอน create และคืน claim ตอน restore

### 4.3 Students

| Flow | Read | Write path | Side effects / rules |
| --- | --- | --- | --- |
| List students | `children`, `schools`, `trips` | ไม่มี | แสดง school name และ trip assignment |
| Create child | `children`, `parents`, `schools` | direct Firestore transaction `saveChild()` | เพิ่ม `childIds` ใน parent และ sync `parent.schoolIds` |
| Edit child | `children`, `parents`, `schools` | direct Firestore transaction `saveChild()` | ถ้าเปลี่ยน parent จะ remove จาก parent เดิมและ add ให้ parent ใหม่ |
| Archive / restore child | `children`, `trips`, `buses`, `parents` | direct Firestore transaction `setChildArchived()` | ถ้า archive จะ unassign จาก trip/bus และ reset assignment state |
| Remove from trip | `children`, `trips`, `buses`, `parents` | direct Firestore transaction `removeChildFromTrip()` | ลบ child ออกจาก trip/bus และ sync `parent.schoolIds` |

field หลักที่ UI ส่งตอน create/edit:

- `id`
- `name`
- `parentId`
- `schoolId`
- `homeAddress`
- `pickupLabel`
- `pickupLat`
- `pickupLng`
- `photoUrl`
- `schoolName`
- `gradeLevel`
- `emergencyContactName`
- `emergencyContactPhone`

behavior สำคัญ:

- child ต้องมี parent ที่ active
- child ต้องมี school ที่ active
- ถ้ายังไม่มี assignment จะได้ `assignmentStatus = 'pending'`
- ถ้ามี `tripId` หรือ `busId` อยู่แล้ว จะถือเป็น `assignmentStatus = 'assigned'`
- ถ้าไม่มี `qrCodeValue` เดิม จะสร้างเป็น `SKS-CHILD-<CHILD_ID>`

### 4.4 Fleet

| Flow | Read | Write path | Side effects / rules |
| --- | --- | --- | --- |
| List buses | `buses`, `drivers` | ไม่มี | แสดงชื่อ driver จาก `bus.driverId` |
| Create bus | `buses`, `drivers` | direct Firestore transaction `saveBus()` | sync ความสัมพันธ์ bus-driver ทั้งสองฝั่ง |
| Edit bus | `buses`, `drivers` | direct Firestore transaction `saveBus()` | ถ้าเปลี่ยน driver จะ clear bus เดิมของ driver ใหม่ และ clear driver เดิมของ bus นี้ |
| Archive / restore bus | `buses`, `children`, `trips` | direct Firestore `setBusArchived()` | archive ได้ต่อเมื่อไม่มี active assigned children และไม่มี open trips |

field หลักที่ UI ส่งตอน create/edit:

- `id`
- `busNumber`
- `licensePlate`
- `driverId`
- `schoolId`
- `currentLat`
- `currentLng`

behavior สำคัญ:

- `status` ของ bus ถ้ายังไม่มีจะ default เป็น `'waiting'`
- `childIds`, `estimatedArrival`, archive state เดิม จะถูกคงไว้ตอน edit

### 4.5 Trips

| Flow | Read | Write path | Side effects / rules |
| --- | --- | --- | --- |
| List trips | `trips`, `schools`, `buses`, `children` | ไม่มี | filter ด้วย `schoolIds`; reader fallback จาก legacy `schoolId` |
| Preview route | `buses`, `children`, `schools` | callable `manageTrip` action `calculateRoute` | derive schools/stops, validate conflicts และคืน input hash |
| Create / edit trip | related records | callable `manageTrip` action `create` / `update` | backend สร้าง canonical grouped stops และ sync child assignment |
| Archive / restore trip | `trips`, `children`, `parents` | callable `manageTrip` action `archive` / `restore` | archive unassign เด็ก; legacy draft/archived convert เมื่อแก้ |
| Delete trip | `trips`, `children`, `buses` | callable `manageTrip` action `delete` | ลบถาวรทุกสถานะ, unassign เด็ก และคืน active bus เป็น `waiting` |

field หลักที่ UI ส่งตอน create/edit:

- `id`
- `busId`
- `serviceDate`
- `round`
- `scheduledStartAt`
- `childIds`
- `origin`: `{ lat, lng, label }`
- `routePlan` ที่ได้จาก `calculateRoute`

business rules สำคัญ:

- trip ต้องมี active bus, เด็กอย่างน้อยหนึ่งคน และ origin ที่มีพิกัด
- backend derive `schoolIds`; เด็กและโรงเรียนทั้งหมดต้อง active และมีพิกัด
- home stops รวมด้วยพิกัดปัด 5 ตำแหน่ง; school stops รวมตาม `schoolId`
- `toSchool`: home pickup → school drop; `toHome`: school pickup → home drop
- save ได้เมื่อ `routePlan.inputHash` ตรงกับ inputs ปัจจุบันเท่านั้น
- ห้ามมี bus ซ้ำใน open trip รอบเดียวกันของ `serviceDateKey`
- ห้ามมี child ซ้ำใน open trip รอบเดียวกันของ `serviceDateKey`
- API ล้มเหลวให้เรียก `calculateRoute` พร้อม `manual: true`; reorder ได้เฉพาะภายใน phase

## 5. Data Contract Summary ของ Collection ที่เกี่ยวข้อง

## 5.1 `app_users`

ใช้สำหรับ auth profile และ role resolution

field ที่ทีมเว็บควรรู้:

- `name`
- `role`: `parent` | `teacher` | `driver` | `admin`
- `referenceId`: id ของ role document เช่น `parent_xxx`, `driver_xxx`
- `profilePhotoPath`
- `email`
- `createdAt`
- `updatedAt`
- `isArchived`
- `archivedAt`

## 5.2 `schools`

field ที่ใช้ใน admin:

- `name`
- `address`
- `lat`
- `lng`
- `morningPickup`
- `morningDropoff`
- `eveningPickup`
- `eveningDropoff`
- `isArchived`
- `archivedAt`
- `updatedAt`

## 5.3 `parents`

field ที่ใช้ใน admin:

- `name`
- `phone`
- `childIds`
- `schoolIds`
- `isArchived`
- `archivedAt`
- `updatedAt`

หมายเหตุ:

- UI filter parent ตาม `schoolIds`
- `schoolIds` ถูก sync จาก `children.parentId`

## 5.4 `teachers`

field ที่ใช้ใน admin:

- `name`
- `schoolId`
- `isArchived`
- `archivedAt`
- `updatedAt`

## 5.5 `drivers`

field ที่ใช้ใน admin:

- `name`
- `phone`
- `busId`
- `licenseNumber`
- `schoolId`
- `isArchived`
- `archivedAt`
- `updatedAt`

## 5.6 `admins`

field ที่ใช้ใน admin:

- `name`
- `schoolId`
- `isArchived`
- `archivedAt`
- `updatedAt`

## 5.7 `children`

field ที่ทีมเว็บต้องไม่พลาด:

- `name`
- `parentId`
- `tripId`
- `busId`
- `busStopId`
- `schoolId`
- `homeAddress`
- `pickupLabel`
- `pickupLat`
- `pickupLng`
- `qrCodeValue`
- `photoUrl`
- `schoolName`
- `gradeLevel`
- `emergencyContactName`
- `emergencyContactPhone`
- `assignmentStatus`: `pending` | `assigned`
- `isArchived`
- `archivedAt`
- `hasBoarded`
- `hasArrived`
- `updatedAt`

## 5.8 `buses`

field ที่ทีมเว็บต้องไม่พลาด:

- `busNumber`
- `driverId`
- `schoolId`
- `childIds`
- `licensePlate`
- `status`: `waiting` | `enRoute` | `arrived`
- `currentLat`
- `currentLng`
- `estimatedArrival`
- `isArchived`
- `archivedAt`
- `updatedAt`

## 5.9 `trips`

field ที่ทีมเว็บต้องไม่พลาด:

- `schoolIds`
- `routeVersion`: `2` สำหรับ multi-school workflow
- `busId`
- `serviceDate`
- `serviceDateKey`
- `round`: `toSchool` | `toHome`
- `scheduledStartAt`
- `childIds`
- `origin`: `{ lat, lng, label }`
- `stops`: grouped stop ที่มี `id`, `type`, `action`, `childIds`, `schoolId`, พิกัด, `sequence`, `status`
- `routePlan`: provider, input hash, metrics, polylines, calculated time และ manual flag
- `currentStopIndex`
- `status`: `draft` | `active` | `completed` | `cancelled`
- `isArchived`
- `archivedAt`
- `startedAt`
- `completedAt`
- `createdAt`
- `updatedAt`

หมายเหตุ:

- query conflict ของ trip พึ่ง index `(serviceDateKey, round)`
- legacy `schoolId` ต้องอ่านเป็น `schoolIds: [schoolId]`

## 6. Callable Function Contract

## 6.1 Current mobile usage

### `manageUser`

สถานะ:

- ใช้งานจริงจาก Flutter admin ปัจจุบัน

region:

- `asia-southeast1`

action ที่รองรับ:

- `create`
- `update`
- `archive`
- `restore`

payload หลัก:

- `action`
- `role`
- `uid`
- `referenceId`
- `name`
- `email`
- `phone`
- `licenseNumber`
- `password`
- `busId`
- `schoolId`

behavior:

- `create`: สร้าง Firebase Auth user, role document, และ `app_users`
- `update`: update Firebase Auth user + role document + `app_users`
- `archive`: disable Auth user และ set `isArchived`
- `restore`: enable Auth user และคืนสถานะ `isArchived`

response โดยรวม:

- `create` คืนอย่างน้อย `uid` และ `referenceId`
- action อื่นคืน `{ ok: true }`

## 6.2 Structural callable functions

Flutter และ Web ใช้ callable สำหรับ structural writes:

- `manageSchool`
- `manageBus`
- `manageTrip`

`manageTrip` รองรับ `calculateRoute`, `create`, `update`, `archive`, `restore`, `delete` และ `setStatus`.
`calculateRoute` รับ `busId`, `round`, วันที่/เวลา, `childIds`, `origin` และ optional `manual`; response คืน canonical stops, `schoolIds`, metrics, polylines และ `inputHash`.
`delete` รับ `id`, ลบทริปได้ทุกสถานะ, unassign เด็กที่ยังชี้มาทริป และคืน active bus เป็น `waiting`.

Route Optimization ใช้ `optimizeTours` สอง phase. Runtime service account ต้องมี `routeoptimization.locations.use` และ project ต้องเปิด Route Optimization API/billing. Deploy Functions ก่อน release Web/Flutter แล้วจึง deploy strict Rules.

`startDriverTrip` ใช้สำหรับคนขับเริ่มทริป โดยตรวจว่าคนขับผูกกับรถของทริปก่อนใช้ GPS ล่าสุดคำนวณลำดับ stop ใหม่แบบ nearest-neighbor ตามระยะทางขับจริง แยก home/school เป็นสอง phase แล้วเปลี่ยนสถานะทริปและรถใน transaction เดียว หาก GPS หรือ Routes API ใช้ไม่ได้จะเริ่มด้วย route ที่บันทึกไว้เดิม ทริป legacy v1 ไม่คำนวณใหม่

Dynamic driver routing ต้องเปิด Google Maps Routes API และ billing เพิ่มเติม Functions ใช้ OAuth ของ runtime service account เรียก `Compute Route Matrix` และ `Compute Routes`.

## 7. Business Rules ที่ทีมเว็บต้องตามให้ตรง

- archive school ได้เมื่อไม่มี active `teachers`, active `children`, และ open `trips`
- archive bus ได้เมื่อไม่มี active assigned `children` และ open `trips`
- archive parent ไม่ได้ถ้ายังมี active `children`
- archive driver ไม่ได้ถ้ายังผูกกับ active `bus`
- child ต้องมี active `parent` และ active `school`
- trip v2 ต้องมี active bus; backend derive และ validate active schools จากเด็กทุกคน
- เด็กและโรงเรียนที่ไม่มีพิกัดห้ามนำมาคำนวณ route
- grouped stop progress มีผลกับเด็กทุกคนใน `childIds`
- ห้าม reorder stop ข้าม phase และ save ต้องใช้ input hash ล่าสุด
- ห้าม bus ซ้ำใน open trip รอบเดียวกันของ `serviceDateKey`
- ห้าม child ซ้ำใน open trip รอบเดียวกันของ `serviceDateKey`
- ตอน archive child / remove child from trip / archive หรือ delete trip ต้อง sync ค่า `tripId`, `busId`, `assignmentStatus`, `hasBoarded`, `hasArrived`
- ตอนเปลี่ยน child-parent relation ต้อง sync `parents.childIds`
- ตอน child set เปลี่ยน ต้อง sync `parents.schoolIds`
- ตอนเปลี่ยน bus-driver relation ต้อง sync ทั้ง `buses.driverId` และ `drivers.busId`

## 8. Interface / Type Summary ที่อ้างอิงในระบบ

## 8.1 `AdminManagedUserInput`

- `uid`
- `referenceId`
- `type`
- `name`
- `email`
- `phone`
- `licenseNumber`
- `password`
- `busId`
- `schoolId`

## 8.2 `AdminSchoolInput`

- `id`
- `name`
- `address`
- `lat`
- `lng`
- `morningPickup`
- `morningDropoff`
- `eveningPickup`
- `eveningDropoff`

## 8.3 `AdminBusInput`

- `id`
- `busNumber`
- `licensePlate`
- `driverId`
- `schoolId`
- `currentLat`
- `currentLng`

## 8.4 `AdminChildInput`

- `id`
- `name`
- `parentId`
- `schoolId`
- `homeAddress`
- `pickupLabel`
- `schoolName`
- `gradeLevel`
- `emergencyContactName`
- `emergencyContactPhone`
- `pickupLat`
- `pickupLng`
- `photoUrl`

## 8.5 `AdminTripInput`

- `id`
- `busId`
- `serviceDate`
- `round`
- `scheduledStartAt`
- `childIds`
- `origin`
- `routePlan`

## 8.6 Enum values ที่เกี่ยวข้อง

- `TripRound`: `toSchool`, `toHome`
- `TripStatus`: `draft`, `active`, `completed`, `cancelled`
- `ChildAssignmentStatus`: `pending`, `assigned`

## 9. Known Implementation Notes

- mobile admin อ่านข้อมูลทั้งหมดแบบ realtime ผ่าน Firestore `snapshots()`
- School, Bus และ Trip structural mutations ใช้ callable; realtime reads ยังใช้ Firestore
- Rules อนุญาต driver แก้เฉพาะ Trip status/current stop/timestamps/stop progress
- Web/Flutter debounce route calculation 800ms และทิ้ง stale response
- active legacy trip ใช้ flow เดิมจนจบ; draft/archived legacy trip convert เป็น v2 เมื่อแก้
- ถ้าทีมเว็บเป็นคนละแอป ให้ยึด Firebase contract ในเอกสารนี้เป็นหลัก มากกว่าวิธีจัด state ใน Flutter
