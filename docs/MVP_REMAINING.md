# MVP - Remaining Work

Updated 2026-01-17.

---

## TO DO

### 1. Equipment Expansion (UI Forms)
Database schema v14 is ready with all fields. UI needs updating:
- Update `lib/screens/bow_form_screen.dart` to use new database columns instead of settings string
- Create stabilizer form/detail screens
- Create string form/detail screens
- Update shaft_detail_screen with new fields (totalWeight, pointType, nockBrand, fletchingSize, fletchingAngle, wrap, purchaseDate)

**New DB columns available:**
- Bows: riserModel, riserPurchaseDate, limbModel, limbPurchaseDate, poundage, tillerTop, tillerBottom, braceHeight, nockingPointHeight, buttonPosition, buttonTension, clickerPosition
- Shafts: totalWeight, pointType, nockBrand, fletchingSize, fletchingAngle, hasWrap, wrapColor, purchaseDate
- Stabilizers table: longRodModel/Length/Weight, sideRodModel/Length/Weight, extenderLength, vbarModel/AngleH/AngleV, weightArrangement, damperModel/Positions
- BowStrings table: material, strandCount, servingMaterial, stringLength, color, purchaseDate

### 2. Group Visualization Settings
Ellipse already works. Still need:
- Color arrows by end (pass end info to widget)
- Ring notation ("9.2 group" display)
- Settings toggles in plotting preferences

### 3. Nock Rotation Setting
- Settings toggle in plotting preferences
- Add nockRotation column to Arrows table (nullable TEXT: '12', '4', '8')
- Update shaft selector UI with rear-view arrow graphic
- Store selected nock position

---

## Post-MVP (Defer)

- Clicks-per-ring wizard
- 252 scheme tracker
- OLY training system upgrade
