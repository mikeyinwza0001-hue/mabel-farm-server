# แก้บัค Farm Mini-Game 3 จุด

## Bug 1: ไฟลอยกลางอากาศตอน Shrink ฟาร์ม 🔥

**สาเหตุ:** เมื่อ shrink ฟาร์ม, [trimWheatOutsideBounds()](file:///d:/Coding%20Project/Minecraft/Farm/mabel-ricefarm/src/main/java/com/mabel/ricefarm/FarmGame.java#378-416) ลบเฉพาะ **wheat, farmland, water, snow_block** ที่อยู่นอกขอบใหม่ แต่**ไม่ได้ลบ fire และ dirt** — ทำให้ไฟที่อยู่ตำแหน่ง `centerY` ยังคงอยู่บนอากาศ (เพราะ farmland ใต้มันถูกเปลี่ยนเป็น dirt ตอน dragon โจมตี แล้ว dirt ไม่ถูกลบ)

### Proposed Changes

#### [MODIFY] [FarmGame.java](file:///d:/Coding%20Project/Minecraft/Farm/mabel-ricefarm/src/main/java/com/mabel/ricefarm/FarmGame.java)

ใน [trimWheatOutsideBounds()](file:///d:/Coding%20Project/Minecraft/Farm/mabel-ricefarm/src/main/java/com/mabel/ricefarm/FarmGame.java#378-416) — เพิ่มการเช็คและลบ `FIRE` blocks ที่ `centerY` และเปลี่ยน `DIRT` blocks ที่ `centerY-1` เป็น `AIR` สำหรับตำแหน่งที่อยู่นอกขอบเขตใหม่:

```diff
 if (!isInFarm(x, z)) {
     Block crop = w.getBlockAt(x, centerY, z);
-    if (crop.getType() == Material.WHEAT) crop.setType(Material.AIR, false);
+    if (crop.getType() == Material.WHEAT || crop.getType() == Material.FIRE)
+        crop.setType(Material.AIR, false);
     Block below = w.getBlockAt(x, centerY - 1, z);
-    if (below.getType() == Material.FARMLAND) {
+    if (below.getType() == Material.FARMLAND || below.getType() == Material.DIRT) {
         below.setType(Material.AIR, false);
         w.getBlockAt(x, centerY - 2, z).setType(Material.AIR, false);
     }
```

---

## Bug 2: ปาขวดน้ำดับไฟเป็นกลุ่มใหญ่หลัง Resize 💧

**สาเหตุ:** ปัญหาคือ [dragonFireLoop()](file:///d:/Coding%20Project/Minecraft/Farm/mabel-ricefarm/src/main/java/com/mabel/ricefarm/FarmGame.java#206-214) วิ่งทุก 1 วินาที และ re-place fire บน **ทุก dirt block ในขอบเขตฟาร์มปัจจุบัน** — เมื่อ shrink/expand แล้ว ขอบเขตเปลี่ยน ทำให้เวลาดับไฟ 1 จุด → [dragonFireLoop](file:///d:/Coding%20Project/Minecraft/Farm/mabel-ricefarm/src/main/java/com/mabel/ricefarm/FarmGame.java#206-214) จะ re-ignite มันทันที → ผู้เล่นต้องดับทั้งหมดในรอบเดียว

**แก้ไข:** เปลี่ยน [dragonFireLoop()](file:///d:/Coding%20Project/Minecraft/Farm/mabel-ricefarm/src/main/java/com/mabel/ricefarm/FarmGame.java#206-214) ให้**ไม่ re-place fire** ถ้า block บนเป็น AIR (คือถูกดับแล้ว) — ให้ re-place เฉพาะตอนที่ block บนยังเป็น fire เท่านั้น (เพื่อไม่ให้ไฟหายเอง) + เพิ่ม flag per-block ว่าไฟถูกดับแล้วหรือยัง

**แก้ไขแบบง่ายกว่า:** ลบ [dragonFireLoop()](file:///d:/Coding%20Project/Minecraft/Farm/mabel-ricefarm/src/main/java/com/mabel/ricefarm/FarmGame.java#206-214) ทิ้งเลย เพราะมันไม่จำเป็น — fire ที่ตั้งไว้จะไม่หายเองเพราะ `BlockPhysicsEvent` cancel ไว้แล้ว ดังนั้น loop ที่ set fire ซ้ำทุก 1 วินาทีทำให้ดับไม่ได้

### Proposed Changes

#### [MODIFY] [FarmGame.java](file:///d:/Coding%20Project/Minecraft/Farm/mabel-ricefarm/src/main/java/com/mabel/ricefarm/FarmGame.java)

1. ลบ [dragonFireLoop()](file:///d:/Coding%20Project/Minecraft/Farm/mabel-ricefarm/src/main/java/com/mabel/ricefarm/FarmGame.java#206-214) method ออก (&lsquo;ไม่ต้องทำ fire loop ซ้ำ เพราะ fire ถูก protect ด้วย BlockPhysicsEvent แล้ว)
2. ลบ `dragonFireTask` จาก [startLoops()](file:///d:/Coding%20Project/Minecraft/Farm/mabel-ricefarm/src/main/java/com/mabel/ricefarm/FarmGame.java#175-180) และ [stopLoops()](file:///d:/Coding%20Project/Minecraft/Farm/mabel-ricefarm/src/main/java/com/mabel/ricefarm/FarmGame.java#181-186)
3. ใน [startLoops()](file:///d:/Coding%20Project/Minecraft/Farm/mabel-ricefarm/src/main/java/com/mabel/ricefarm/FarmGame.java#175-180) ลบ `dragonFireTask = new BukkitRunnable...`

> [!IMPORTANT]
> ตอนนี้ [dragonFireLoop](file:///d:/Coding%20Project/Minecraft/Farm/mabel-ricefarm/src/main/java/com/mabel/ricefarm/FarmGame.java#206-214) ทำให้ดับไฟทีละบล็อคไม่ได้เลย เพราะพอดับไป 1 วิ ก็จะถูก re-ignite ทันที เมื่อลบ loop นี้ออกจะทำให้ดับไฟทีละบล็อคได้ตามปกติ

---

## Bug 3: Overlay ไม่รับค่า 📊

**สาเหตุ:** ตรวจสอบแล้วพบว่า [WebOverlay.java](file:///d:/Coding%20Project/Minecraft/Farm/mabel-ricefarm/src/main/java/com/mabel/ricefarm/WebOverlay.java) ใช้ `HttpServer` (ไม่ใช่ Socket.IO) และ overlay HTML poll ผ่าน `fetch('/api/progress')` ทุก 500ms. ตัว API คืนค่า `lastFullGrown` และ `lastTotal` จาก [FarmGame](file:///d:/Coding%20Project/Minecraft/Farm/mabel-ricefarm/src/main/java/com/mabel/ricefarm/FarmGame.java#16-433) ซึ่งอัปเดตใน [gameLoop()](file:///d:/Coding%20Project/Minecraft/Farm/mabel-ricefarm/src/main/java/com/mabel/ricefarm/FarmGame.java#187-205) ทุก 1s

**ปัญหาที่เป็นไปได้:**
1. ตัว `HttpServer` ไม่ bind `0.0.0.0` — ค่าเริ่มต้น `InetSocketAddress(port)` จะ bind `0.0.0.0` อยู่แล้ว ไม่น่ามีปัญหา
2. CORS — มี `Access-Control-Allow-Origin: *` อยู่แล้ว
3. **ปัญหาจริง:** ตอนเปิด overlay จาก OBS หรือ browser ภายนอก เช่นจาก IP/hostname อื่น — ต้องเช็คว่า port ถูกเปิดอยู่ไหม

**ตรวจสอบเพิ่ม:** ดูไฟล์ [overlay/server.js](file:///d:/Coding%20Project/Minecraft/Farm/overlay/server.js) (Node.js server เก่า) — มีทั้งระบบ Node.js (socket.io) และ Java (HTTP polling) พร้อมกัน อาจเกิดปัญหาว่าเปิดเป็น Node server แต่ plugin ก็เปิด port เดียวกัน (5656) ซ้ำกัน

### Proposed Changes

#### [MODIFY] [FarmGame.java](file:///d:/Coding%20Project/Minecraft/Farm/mabel-ricefarm/src/main/java/com/mabel/ricefarm/FarmGame.java)

เพิ่มการ log เมื่ออัปเดต `lastFullGrown`/`lastTotal` ใน [gameLoop()](file:///d:/Coding%20Project/Minecraft/Farm/mabel-ricefarm/src/main/java/com/mabel/ricefarm/FarmGame.java#187-205):
```diff
 lastFullGrown = full; lastTotal = total;
+plugin.getLogger().info("[Overlay] Progress: " + full + "/" + total);
```

> [!NOTE]
> ถ้าปัญหาคือ overlay ไม่รับค่า**เลย** (แสดง 0% ตลอด) — น่าจะเป็นเพราะ **overlay Node.js server ([overlay/server.js](file:///d:/Coding%20Project/Minecraft/Farm/overlay/server.js)) กับ Java plugin server ชนกัน port 5656** หรืออาจเปิด overlay ไม่ถูก URL

ผมจะเพิ่ม logging ก่อน แล้วให้พี่ลองเทสดู ถ้ายังไม่ work จะเพิ่มแก้ไข

---

## Verification Plan

### Manual Verification
เนื่องจากเป็น Minecraft plugin — ผมจะ build jar แล้วให้พี่ลองเทสมือใน game:

1. **Build:** `mvn clean package` ใน `mabel-ricefarm/`
2. **Deploy:** Copy jar ไปที่ `plugins/`
3. **ทดสอบ Bug 1:** `/mbfarm start` → `/mbfarm dragon` → รอไฟติด → `/mbfarm shrink 5` → ดูว่าไฟนอกขอบเขตหายไปหรือยัง
4. **ทดสอบ Bug 2:** `/mbfarm start` → `/mbfarm dragon` → รอไฟติด → ปาขวดน้ำดับไฟทีละจุด → ดูว่าไฟดับเฉพาะจุดที่ปาหรือดับเป็นกลุ่มใหญ่
5. **ทดสอบ Bug 3:** เปิด `http://localhost:5656` ใน browser → `/mbfarm start` → ปลูกข้าว → ดูว่า progress bar ขยับไหม
