-- ============================================
-- CERRAJEROSYA.ES - PRODUCCIÓN SQL SCHEMA
-- Supabase PostgreSQL Database
-- ============================================

-- Extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- ============================================
-- TABLA: professionals
-- ============================================
CREATE TABLE professionals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Información básica
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) NOT NULL,
    whatsapp_phone VARCHAR(20),
    
    -- Ubicación
    city VARCHAR(100) NOT NULL,
    postal_code VARCHAR(10),
    address TEXT,
    location GEOGRAPHY(POINT, 4326), -- PostGIS para geolocalización
    
    -- Especialización
    specialties TEXT[] NOT NULL DEFAULT '{}', -- ['Cerrajería', 'Fontanería']
    service_radius_km INTEGER DEFAULT 20,
    
    -- Finanzas (SALDO RETENIDO)
    balance DECIMAL(10,2) DEFAULT 0.00 NOT NULL CHECK (balance >= 0),
    total_recharged DECIMAL(10,2) DEFAULT 0.00,
    total_spent DECIMAL(10,2) DEFAULT 0.00,
    pending_balance DECIMAL(10,2) DEFAULT 0.00, -- En leads asignados pero no completados
    
    -- Métricas de rendimiento
    reputation DECIMAL(3,2) DEFAULT 5.00 CHECK (reputation >= 0 AND reputation <= 5),
    total_leads_purchased INTEGER DEFAULT 0,
    total_leads_completed INTEGER DEFAULT 0,
    total_leads_cancelled INTEGER DEFAULT 0,
    
    -- Conversion rate (calculado automáticamente)
    conversion_rate DECIMAL(5,2) GENERATED ALWAYS AS (
        CASE 
            WHEN total_leads_purchased > 0 
            THEN ROUND((total_leads_completed::DECIMAL / total_leads_purchased * 100)::NUMERIC, 2)
            ELSE 0 
        END
    ) STORED,
    
    -- Tiempo de respuesta (promedio en segundos)
    avg_response_time_seconds INTEGER DEFAULT 120,
    last_response_time_seconds INTEGER,
    
    -- Estado y verificación
    active BOOLEAN DEFAULT true,
    verified BOOLEAN DEFAULT false,
    verification_date TIMESTAMP WITH TIME ZONE,
    
    -- Integración Stripe
    stripe_customer_id VARCHAR(255) UNIQUE,
    stripe_account_id VARCHAR(255),
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Auditoría
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_active_at TIMESTAMP WITH TIME ZONE,
    
    -- Constraints
    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT valid_phone CHECK (phone ~ '^\+?[0-9]{9,15}$')
);

-- Índices para professionals
CREATE INDEX idx_professionals_city ON professionals(city);
CREATE INDEX idx_professionals_active ON professionals(active) WHERE active = true;
CREATE INDEX idx_professionals_verified ON professionals(verified) WHERE verified = true;
CREATE INDEX idx_professionals_specialties ON professionals USING GIN(specialties);
CREATE INDEX idx_professionals_location ON professionals USING GIST(location);
CREATE INDEX idx_professionals_balance ON professionals(balance) WHERE balance > 0;

COMMENT ON TABLE professionals IS 'Profesionales autónomos verificados de la plataforma';
COMMENT ON COLUMN professionals.balance IS 'Saldo disponible para compra de leads';
COMMENT ON COLUMN professionals.pending_balance IS 'Saldo comprometido en leads asignados no completados';

-- ============================================
-- TABLA: leads
-- ============================================
CREATE TABLE leads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Información del cliente
    client_phone VARCHAR(20) NOT NULL,
    client_name VARCHAR(255),
    client_email VARCHAR(255),
    
    -- Ubicación
    city VARCHAR(100) NOT NULL,
    address TEXT NOT NULL,
    postal_code VARCHAR(10),
    location GEOGRAPHY(POINT, 4326),
    
    -- Servicio
    category VARCHAR(100) NOT NULL, -- 'Cerrajería', 'Fontanería', etc.
    service_type VARCHAR(100), -- 'Apertura de puertas', 'Cambio de cerradura'
    description TEXT,
    urgency_level INTEGER CHECK (urgency_level BETWEEN 1 AND 5) DEFAULT 3,
    
    -- Origen y tracking
    source VARCHAR(50) NOT NULL, -- 'landing', 'vapi', 'whatsapp', 'google_ads'
    utm_source VARCHAR(100),
    utm_medium VARCHAR(100),
    utm_campaign VARCHAR(100),
    google_ad_code VARCHAR(100),
    referrer_url TEXT,
    
    -- Precio del lead
    price DECIMAL(10,2) NOT NULL CHECK (price > 0),
    
    -- Asignación
    assigned_professional_id UUID REFERENCES professionals(id) ON DELETE SET NULL,
    assigned_at TIMESTAMP WITH TIME ZONE,
    assignment_method VARCHAR(50), -- 'auto', 'manual'
    assignment_score DECIMAL(10,2), -- Score del profesional asignado
    
    -- Estado del lead
    status VARCHAR(50) DEFAULT 'pending' CHECK (
        status IN ('pending', 'assigned', 'in_progress', 'completed', 'cancelled', 'refunded')
    ),
    
    -- Timestamps del ciclo de vida
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    cancelled_at TIMESTAMP WITH TIME ZONE,
    
    -- Razón de cancelación
    cancellation_reason TEXT,
    cancelled_by VARCHAR(50), -- 'client', 'professional', 'system'
    
    -- Vapi.ai (llamadas telefónicas)
    call_id VARCHAR(255),
    call_recording_url TEXT,
    call_duration_seconds INTEGER,
    call_transcript TEXT,
    recording_consent BOOLEAN DEFAULT false,
    
    -- Metadata adicional
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Constraints
    CONSTRAINT valid_assignment CHECK (
        (status IN ('assigned', 'in_progress', 'completed') AND assigned_professional_id IS NOT NULL) OR
        (status IN ('pending', 'cancelled', 'refunded'))
    )
);

-- Índices para leads
CREATE INDEX idx_leads_status ON leads(status);
CREATE INDEX idx_leads_city ON leads(city);
CREATE INDEX idx_leads_category ON leads(category);
CREATE INDEX idx_leads_created_at ON leads(created_at DESC);
CREATE INDEX idx_leads_assigned_professional ON leads(assigned_professional_id);
CREATE INDEX idx_leads_source ON leads(source);
CREATE INDEX idx_leads_location ON leads USING GIST(location);
CREATE INDEX idx_leads_pending ON leads(status, city, category) WHERE status = 'pending';

COMMENT ON TABLE leads IS 'Solicitudes de servicio de emergencia';
COMMENT ON COLUMN leads.price IS 'Precio que paga el profesional por este lead';

-- ============================================
-- TABLA: transactions
-- ============================================
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Relaciones
    professional_id UUID NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
    lead_id UUID REFERENCES leads(id) ON DELETE SET NULL,
    
    -- Tipo de transacción
    type VARCHAR(50) NOT NULL CHECK (
        type IN ('recharge', 'lead_purchase', 'refund', 'adjustment', 'withdrawal')
    ),
    
    -- Montos
    amount DECIMAL(10,2) NOT NULL,
    balance_before DECIMAL(10,2) NOT NULL,
    balance_after DECIMAL(10,2) NOT NULL,
    
    -- Estado
    status VARCHAR(50) DEFAULT 'pending' CHECK (
        status IN ('pending', 'completed', 'failed', 'cancelled', 'refunded')
    ),
    
    -- Stripe
    stripe_payment_intent_id VARCHAR(255),
    stripe_charge_id VARCHAR(255),
    stripe_refund_id VARCHAR(255),
    
    -- Descripción
    description TEXT,
    notes TEXT,
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Auditoría
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES auth.users(id),
    
    -- Constraints
    CONSTRAINT valid_transaction_amount CHECK (
        (type = 'recharge' AND amount > 0) OR
        (type IN ('lead_purchase', 'withdrawal') AND amount < 0) OR
        (type IN ('refund', 'adjustment'))
    ),
    CONSTRAINT valid_balance_change CHECK (
        balance_after = balance_before + amount
    )
);

-- Índices para transactions
CREATE INDEX idx_transactions_professional ON transactions(professional_id);
CREATE INDEX idx_transactions_lead ON transactions(lead_id);
CREATE INDEX idx_transactions_type ON transactions(type);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_transactions_created_at ON transactions(created_at DESC);
CREATE INDEX idx_transactions_stripe_payment ON transactions(stripe_payment_intent_id);

COMMENT ON TABLE transactions IS 'Registro completo de transacciones financieras';
COMMENT ON COLUMN transactions.amount IS 'Monto positivo para ingresos, negativo para gastos';

-- ============================================
-- TABLA: audit_logs
-- ============================================
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Contexto
    table_name VARCHAR(100) NOT NULL,
    record_id UUID NOT NULL,
    
    -- Acción realizada
    action VARCHAR(50) NOT NULL CHECK (
        action IN ('create', 'update', 'delete', 'assign', 'cancel', 'complete', 'refund')
    ),
    
    -- Usuario responsable
    user_id UUID REFERENCES auth.users(id),
    user_email VARCHAR(255),
    user_role VARCHAR(50),
    
    -- Datos del cambio
    old_data JSONB,
    new_data JSONB,
    changes JSONB, -- Solo los campos modificados
    
    -- Contexto de la petición
    ip_address INET,
    user_agent TEXT,
    request_id VARCHAR(100),
    
    -- Metadata adicional
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Timestamp
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para audit_logs
CREATE INDEX idx_audit_logs_table_record ON audit_logs(table_name, record_id);
CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_table ON audit_logs(table_name);

COMMENT ON TABLE audit_logs IS 'Registro completo de auditoría de todas las acciones del sistema';

-- ============================================
-- TABLA: service_areas (para multi-ciudad)
-- ============================================
CREATE TABLE service_areas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Ubicación
    country_code VARCHAR(2) NOT NULL,
    country_name VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    region VARCHAR(100),
    
    -- Configuración
    timezone VARCHAR(50) NOT NULL DEFAULT 'Europe/Madrid',
    currency VARCHAR(3) NOT NULL DEFAULT 'EUR',
    language VARCHAR(5) NOT NULL DEFAULT 'es-ES',
    
    -- Pricing
    base_price_multiplier DECIMAL(4,2) DEFAULT 1.00,
    
    -- Estado
    active BOOLEAN DEFAULT true,
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Auditoría
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(country_code, city)
);

CREATE INDEX idx_service_areas_active ON service_areas(active) WHERE active = true;
CREATE INDEX idx_service_areas_country ON service_areas(country_code);

-- ============================================
-- TABLA: system_metrics (para dashboard)
-- ============================================
CREATE TABLE system_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date DATE NOT NULL UNIQUE,
    
    -- Métricas financieras REALES
    total_revenue DECIMAL(10,2) DEFAULT 0.00, -- Ingresos reales del sistema
    total_recharged DECIMAL(10,2) DEFAULT 0.00, -- Total recargado por profesionales
    total_spent_by_professionals DECIMAL(10,2) DEFAULT 0.00, -- Total gastado en leads
    net_revenue DECIMAL(10,2) DEFAULT 0.00, -- Revenue - costes operativos
    
    -- Métricas de saldo (NO son ingresos)
    total_balance_retained DECIMAL(10,2) DEFAULT 0.00, -- Saldo total en cuentas de profesionales
    total_pending_balance DECIMAL(10,2) DEFAULT 0.00, -- Saldo comprometido en leads activos
    
    -- Tickets
    avg_lead_price DECIMAL(10,2) DEFAULT 0.00,
    avg_recharge_amount DECIMAL(10,2) DEFAULT 0.00,
    
    -- Métricas operativas
    total_leads INTEGER DEFAULT 0,
    leads_assigned INTEGER DEFAULT 0,
    leads_completed INTEGER DEFAULT 0,
    leads_cancelled INTEGER DEFAULT 0,
    leads_pending INTEGER DEFAULT 0,
    
    -- Performance
    avg_assignment_time_seconds INTEGER DEFAULT 0,
    avg_completion_time_hours DECIMAL(5,2) DEFAULT 0.00,
    cancellation_rate DECIMAL(5,2) DEFAULT 0.00,
    
    -- Profesionales
    active_professionals INTEGER DEFAULT 0,
    new_professionals INTEGER DEFAULT 0,
    
    -- Timestamp
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_system_metrics_date ON system_metrics(date DESC);

COMMENT ON TABLE system_metrics IS 'Métricas diarias agregadas del sistema';
COMMENT ON COLUMN system_metrics.total_revenue IS 'Ingresos REALES (leads completados), NO saldo retenido';
COMMENT ON COLUMN system_metrics.total_balance_retained IS 'Saldo en cuentas de profesionales (NO es ingreso)';

-- ============================================
-- FUNCIONES Y TRIGGERS
-- ============================================

-- Función: Actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para updated_at
CREATE TRIGGER update_professionals_updated_at 
    BEFORE UPDATE ON professionals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_leads_updated_at 
    BEFORE UPDATE ON leads
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_service_areas_updated_at 
    BEFORE UPDATE ON service_areas
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Función: Audit log automático para leads
CREATE OR REPLACE FUNCTION log_lead_changes()
RETURNS TRIGGER AS $$
DECLARE
    change_data JSONB;
BEGIN
    IF TG_OP = 'UPDATE' THEN
        -- Detectar qué cambió
        change_data := jsonb_build_object(
            'status_changed', OLD.status != NEW.status,
            'old_status', OLD.status,
            'new_status', NEW.status,
            'assignment_changed', OLD.assigned_professional_id != NEW.assigned_professional_id,
            'old_professional_id', OLD.assigned_professional_id,
            'new_professional_id', NEW.assigned_professional_id
        );
        
        INSERT INTO audit_logs (
            table_name, 
            record_id, 
            action, 
            old_data, 
            new_data, 
            changes
        ) VALUES (
            'leads',
            NEW.id,
            'update',
            to_jsonb(OLD),
            to_jsonb(NEW),
            change_data
        );
        
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO audit_logs (
            table_name, 
            record_id, 
            action, 
            new_data
        ) VALUES (
            'leads', 
            NEW.id, 
            'create', 
            to_jsonb(NEW)
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER log_lead_changes_trigger
    AFTER INSERT OR UPDATE ON leads
    FOR EACH ROW EXECUTE FUNCTION log_lead_changes();

-- Función: Actualizar pending_balance cuando se asigna un lead
CREATE OR REPLACE FUNCTION update_pending_balance()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND OLD.status = 'pending' AND NEW.status = 'assigned' THEN
        -- Incrementar pending_balance cuando se asigna
        UPDATE professionals
        SET pending_balance = pending_balance + NEW.price
        WHERE id = NEW.assigned_professional_id;
        
    ELSIF TG_OP = 'UPDATE' AND OLD.status = 'assigned' AND NEW.status IN ('completed', 'cancelled') THEN
        -- Decrementar pending_balance cuando se completa o cancela
        UPDATE professionals
        SET pending_balance = pending_balance - NEW.price
        WHERE id = NEW.assigned_professional_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_pending_balance_trigger
    AFTER UPDATE ON leads
    FOR EACH ROW EXECUTE FUNCTION update_pending_balance();

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Activar RLS
ALTER TABLE professionals ENABLE ROW LEVEL SECURITY;
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Policies para professionals
CREATE POLICY "Professionals can view own data"
    ON professionals FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Professionals can update own data"
    ON professionals FOR UPDATE
    USING (auth.uid() = user_id);

-- Policies para leads
CREATE POLICY "Professionals can view assigned leads"
    ON leads FOR SELECT
    USING (
        assigned_professional_id IN (
            SELECT id FROM professionals WHERE user_id = auth.uid()
        )
    );

-- Policies para transactions
CREATE POLICY "Professionals can view own transactions"
    ON transactions FOR SELECT
    USING (
        professional_id IN (
            SELECT id FROM professionals WHERE user_id = auth.uid()
        )
    );

-- Policies para audit_logs
CREATE POLICY "Admins can view all audit logs"
    ON audit_logs FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    );

-- ============================================
-- VISTAS ÚTILES
-- ============================================

-- Vista: Métricas en tiempo real de profesionales
CREATE OR REPLACE VIEW professional_metrics AS
SELECT 
    p.id,
    p.full_name,
    p.city,
    p.balance,
    p.pending_balance,
    p.balance + p.pending_balance as total_balance,
    p.reputation,
    p.conversion_rate,
    p.avg_response_time_seconds,
    p.total_leads_purchased,
    p.total_leads_completed,
    p.total_leads_cancelled,
    COUNT(l.id) FILTER (WHERE l.status = 'assigned' AND l.created_at > NOW() - INTERVAL '30 days') as leads_last_30_days,
    COALESCE(SUM(l.price) FILTER (WHERE l.status = 'completed' AND l.completed_at > NOW() - INTERVAL '30 days'), 0) as revenue_last_30_days,
    -- Score calculado
    (
        (p.reputation / 5 * 40) +
        (p.conversion_rate / 100 * 30) +
        (LEAST(p.balance / 1000, 1) * 20) +
        (GREATEST(0, 10 - (p.avg_response_time_seconds / 30)) * 10)
    ) as current_score
FROM professionals p
LEFT JOIN leads l ON l.assigned_professional_id = p.id
WHERE p.active = true
GROUP BY p.id;

-- Vista: Leads pendientes de asignación con profesionales disponibles
CREATE OR REPLACE VIEW pending_leads_view AS
SELECT 
    l.*,
    COUNT(p.id) as available_professionals,
    MIN(p.balance) as min_professional_balance,
    MAX(p.reputation) as max_professional_reputation
FROM leads l
LEFT JOIN professionals p ON 
    p.active = true 
    AND p.verified = true
    AND p.city = l.city 
    AND p.specialties && ARRAY[l.category]::TEXT[]
    AND p.balance >= l.price
WHERE l.status = 'pending'
GROUP BY l.id;

-- Vista: Ingresos reales del sistema
CREATE OR REPLACE VIEW real_revenue_view AS
SELECT 
    DATE(l.completed_at) as date,
    COUNT(l.id) as leads_completed,
    SUM(l.price) as total_revenue,
    AVG(l.price) as avg_ticket,
    SUM(t.amount) FILTER (WHERE t.type = 'recharge') as total_recharged
FROM leads l
LEFT JOIN transactions t ON t.lead_id = l.id
WHERE l.status = 'completed'
GROUP BY DATE(l.completed_at)
ORDER BY date DESC;

-- ============================================
-- DATOS INICIALES
-- ============================================

-- Áreas de servicio iniciales
INSERT INTO service_areas (country_code, country_name, city, active) VALUES
('ES', 'España', 'Madrid', true),
('ES', 'España', 'Barcelona', true),
('ES', 'España', 'Valencia', true),
('ES', 'España', 'Sevilla', true),
('ES', 'España', 'Bilbao', true),
('ES', 'España', 'Málaga', true),
('ES', 'España', 'Zaragoza', true);

-- ============================================
-- COMENTARIOS FINALES
-- ============================================

COMMENT ON DATABASE postgres IS 'cerrajerosya.es - Sistema de gestión de leads de emergencia';

-- Fin del schema
