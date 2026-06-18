-- =====================================================
-- BENGKELIN APP — SUPABASE SQL MIGRATION (v2)
-- Urutan: buat tabel dasar dulu, baru tabel turunan
-- Jalankan di: Supabase Dashboard > SQL Editor > New Query
-- =====================================================

-- ══════════════════════════════════════════════════════
-- STEP 1: Tabel PROFILES (biasanya sudah ada dari auth)
-- Pastikan ada kolom role, phone
-- ══════════════════════════════════════════════════════
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'customer';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- ══════════════════════════════════════════════════════
-- STEP 2: Tabel BENGKELS (Mitra Bengkel) ← HARUS DIBUAT DULU
-- ══════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS bengkels (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  address TEXT,
  city TEXT,
  province TEXT,
  phone TEXT,
  description TEXT,
  rating NUMERIC(2,1) DEFAULT 0.0,
  review_count INTEGER DEFAULT 0,
  is_sos_available BOOLEAN DEFAULT false,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  open_hour TEXT DEFAULT '08:00',
  close_hour TEXT DEFAULT '17:00',
  specialization TEXT[] DEFAULT '{}',
  status TEXT NOT NULL DEFAULT 'pending', -- 'pending' | 'active' | 'suspended'
  is_verified BOOLEAN DEFAULT false,
  image_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

ALTER TABLE bengkels ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public can read active bengkels" ON bengkels FOR SELECT USING (status = 'active' OR owner_id = auth.uid());
CREATE POLICY "Owners can update their bengkel" ON bengkels FOR UPDATE USING (owner_id = auth.uid());
CREATE POLICY "Owners can insert bengkel" ON bengkels FOR INSERT WITH CHECK (owner_id = auth.uid());
CREATE POLICY "Admin can manage all bengkels" ON bengkels FOR ALL USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- ══════════════════════════════════════════════════════
-- STEP 3: Tabel VEHICLES (Kendaraan Pelanggan)
-- ══════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS vehicles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  brand TEXT NOT NULL,
  type TEXT NOT NULL,
  year INTEGER,
  plate_number TEXT,
  is_active BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own vehicles" ON vehicles FOR ALL USING (auth.uid() = user_id);

-- ══════════════════════════════════════════════════════
-- STEP 4: Tabel MECHANICS (Mekanik)
-- ══════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS mechanics (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  bengkels_id UUID REFERENCES bengkels(id) ON DELETE SET NULL,
  full_name TEXT NOT NULL,
  phone TEXT,
  operational_status TEXT NOT NULL DEFAULT 'Offline', -- 'Available' | 'On-Duty' | 'Offline'
  current_latitude DOUBLE PRECISION,
  current_longitude DOUBLE PRECISION,
  rating NUMERIC(2,1) DEFAULT 0.0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE mechanics ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public can read mechanics" ON mechanics FOR SELECT USING (true);
CREATE POLICY "Mechanics can update own record" ON mechanics FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Partners can manage bengkel mechanics" ON mechanics FOR ALL USING (
  bengkels_id IN (SELECT id FROM bengkels WHERE owner_id = auth.uid())
);

-- ══════════════════════════════════════════════════════
-- STEP 5: Tabel HOME_SERVICE_TASKS (Panggilan Home/SOS)
-- ══════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS home_service_tasks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  customer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  user_id UUID,
  mechanic_id UUID REFERENCES mechanics(id) ON DELETE SET NULL,
  bengkel_id UUID REFERENCES bengkels(id) ON DELETE SET NULL,
  is_sos BOOLEAN DEFAULT false,
  service_name TEXT NOT NULL DEFAULT 'Home Service',
  customer_name TEXT,
  address TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  notes TEXT,
  vehicle_brand TEXT,
  vehicle_type TEXT,
  vehicle_plate TEXT,
  vehicle_info TEXT,
  status TEXT NOT NULL DEFAULT 'Pending', -- 'Pending' | 'Accepted' | 'Completed' | 'Rejected'
  rejection_reason TEXT,
  estimated_cost INTEGER DEFAULT 0,
  rating NUMERIC(2,1),
  date TEXT,
  time TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

ALTER TABLE home_service_tasks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Customers can manage own tasks" ON home_service_tasks FOR ALL USING (auth.uid() = customer_id);
CREATE POLICY "Mechanics can read and update tasks" ON home_service_tasks FOR ALL USING (
  mechanic_id IN (SELECT id FROM mechanics WHERE user_id = auth.uid())
  OR auth.uid() = customer_id
);
CREATE POLICY "Partners can read tasks for their bengkel" ON home_service_tasks FOR SELECT USING (
  bengkel_id IN (SELECT id FROM bengkels WHERE owner_id = auth.uid())
);

-- ══════════════════════════════════════════════════════
-- STEP 6: Tabel SERVICE_REPORTS (Laporan Mekanik)
-- ══════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS service_reports (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  task_id UUID REFERENCES home_service_tasks(id) ON DELETE CASCADE,
  mechanic_id UUID REFERENCES mechanics(id) ON DELETE SET NULL,
  description TEXT NOT NULL,
  photo_url TEXT,
  spare_parts_used TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE service_reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone authenticated can read reports" ON service_reports FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "Mechanics can insert reports" ON service_reports FOR INSERT WITH CHECK (
  mechanic_id IN (SELECT id FROM mechanics WHERE user_id = auth.uid())
);

-- ══════════════════════════════════════════════════════
-- STEP 7: Tabel ORDERS (Pesanan Sparepart & Layanan)
-- ══════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS orders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  bengkel_id UUID REFERENCES bengkels(id) ON DELETE SET NULL,
  type TEXT NOT NULL DEFAULT 'Sparepart',
  status TEXT NOT NULL DEFAULT 'pending', -- 'pending' | 'Accepted' | 'Processing' | 'Completed' | 'Rejected'
  total INTEGER NOT NULL DEFAULT 0,
  notes TEXT,
  order_type TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own orders" ON orders FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own orders" ON orders FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Partners can read orders for their bengkel" ON orders FOR SELECT USING (
  bengkel_id IN (SELECT id FROM bengkels WHERE owner_id = auth.uid())
);
CREATE POLICY "Partners can update orders for their bengkel" ON orders FOR UPDATE USING (
  bengkel_id IN (SELECT id FROM bengkels WHERE owner_id = auth.uid())
);

-- ══════════════════════════════════════════════════════
-- STEP 8: Tabel BOOKINGS (Jadwal Fisik ke Bengkel)
-- ══════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS bookings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  bengkel_id UUID REFERENCES bengkels(id) ON DELETE SET NULL,
  vehicle_id TEXT,
  scheduled_date DATE,
  time_slot TEXT,
  notes TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own bookings" ON bookings FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Partners can read bookings for their bengkel" ON bookings FOR SELECT USING (
  bengkel_id IN (SELECT id FROM bengkels WHERE owner_id = auth.uid())
);

-- ══════════════════════════════════════════════════════
-- STEP 9: Tabel SPARE_PARTS (Inventaris Mitra)
-- ══════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS spare_parts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  bengkel_id UUID REFERENCES bengkels(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'Lainnya',
  price INTEGER NOT NULL DEFAULT 0,
  stock INTEGER NOT NULL DEFAULT 0,
  description TEXT,
  compatibility_tags JSONB DEFAULT '["mobil"]',
  image_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

ALTER TABLE spare_parts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public can read spare_parts" ON spare_parts FOR SELECT USING (true);
CREATE POLICY "Partners can manage their spare_parts" ON spare_parts FOR ALL USING (
  bengkel_id IN (SELECT id FROM bengkels WHERE owner_id = auth.uid())
);

-- ══════════════════════════════════════════════════════
-- STEP 10: Tabel CHAT_MESSAGES (In-App Chat Realtime)
-- ══════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  task_id TEXT NOT NULL,
  sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  sender_role TEXT NOT NULL DEFAULT 'mechanic',
  message TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated users can read chat messages" ON chat_messages FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated users can send messages" ON chat_messages FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- ══════════════════════════════════════════════════════
-- STEP 11: Tabel REVIEWS (Ulasan Pelanggan)
-- ══════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS reviews (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  target_id TEXT NOT NULL,
  target_type TEXT NOT NULL DEFAULT 'bengkel',
  rating NUMERIC(2,1) NOT NULL DEFAULT 5.0 CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public can read reviews" ON reviews FOR SELECT USING (true);
CREATE POLICY "Users can insert own reviews" ON reviews FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ══════════════════════════════════════════════════════
-- STEP 12: Tabel WITHDRAWALS (Penarikan Dana Mitra)
-- ══════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS withdrawals (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  bengkel_id UUID REFERENCES bengkels(id) ON DELETE CASCADE,
  amount INTEGER NOT NULL,
  bank_name TEXT NOT NULL,
  account_number TEXT NOT NULL,
  account_name TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  rejection_reason TEXT,
  processed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE withdrawals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Partners can manage own withdrawals" ON withdrawals FOR ALL USING (
  bengkel_id IN (SELECT id FROM bengkels WHERE owner_id = auth.uid())
);
CREATE POLICY "Admin can manage all withdrawals" ON withdrawals FOR ALL USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- ══════════════════════════════════════════════════════
-- STEP 13: Aktifkan Realtime
-- ══════════════════════════════════════════════════════
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE orders;
ALTER PUBLICATION supabase_realtime ADD TABLE home_service_tasks;
ALTER PUBLICATION supabase_realtime ADD TABLE mechanics;

-- ══════════════════════════════════════════════════════
-- VERIFIKASI — semua tabel yang terbuat
-- ══════════════════════════════════════════════════════
SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;
