-- Migration: Add tracking and metadata columns
-- Created: 2025-01-24
-- Description: Add columns for tracking views, updates, and metadata

-- ============================================
-- COMPLAINTS TABLE UPDATES
-- ============================================

-- Add is_viewed column to track if user has seen the complaint update
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name='complaints'
        AND column_name='is_viewed'
    ) THEN
        ALTER TABLE complaints
        ADD COLUMN is_viewed BOOLEAN DEFAULT FALSE;

        RAISE NOTICE '✓ Added is_viewed column to complaints table';
    END IF;
END
$$;

-- Add viewed_at column to track when user viewed the complaint
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name='complaints'
        AND column_name='viewed_at'
    ) THEN
        ALTER TABLE complaints
        ADD COLUMN viewed_at TIMESTAMPTZ;

        RAISE NOTICE '✓ Added viewed_at column to complaints table';
    END IF;
END
$$;

-- ============================================
-- SOS_ALERTS TABLE UPDATES
-- ============================================

-- Add is_viewed column to track if user has seen the alert status
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name='sos_alerts'
        AND column_name='is_viewed'
    ) THEN
        ALTER TABLE sos_alerts
        ADD COLUMN is_viewed BOOLEAN DEFAULT FALSE;

        RAISE NOTICE '✓ Added is_viewed column to sos_alerts table';
    END IF;
END
$$;

-- Add viewed_at column to track when user viewed the alert
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name='sos_alerts'
        AND column_name='viewed_at'
    ) THEN
        ALTER TABLE sos_alerts
        ADD COLUMN viewed_at TIMESTAMPTZ;

        RAISE NOTICE '✓ Added viewed_at column to sos_alerts table';
    END IF;
END
$$;

-- ============================================
-- VERIFICATION QUERY
-- ============================================

-- Display the newly added columns
SELECT
    table_name as "Table Name",
    column_name as "Column Name",
    data_type as "Data Type",
    is_nullable as "Nullable",
    column_default as "Default Value"
FROM
    information_schema.columns
WHERE
    table_name IN ('complaints', 'sos_alerts')
    AND column_name IN ('is_viewed', 'viewed_at')
ORDER BY
    table_name,
    ordinal_position;

-- ============================================
-- INDEXES FOR BETTER PERFORMANCE
-- ============================================

-- Create index on complaints is_viewed for faster queries
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_indexes
        WHERE tablename = 'complaints'
        AND indexname = 'idx_complaints_is_viewed'
    ) THEN
        CREATE INDEX idx_complaints_is_viewed
        ON complaints(is_viewed);

        RAISE NOTICE '✓ Created index on complaints(is_viewed)';
    END IF;
END
$$;

-- Create index on sos_alerts is_viewed for faster queries
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_indexes
        WHERE tablename = 'sos_alerts'
        AND indexname = 'idx_sos_alerts_is_viewed'
    ) THEN
        CREATE INDEX idx_sos_alerts_is_viewed
        ON sos_alerts(is_viewed);

        RAISE NOTICE '✓ Created index on sos_alerts(is_viewed)';
    END IF;
END
$$;

-- ============================================
-- HELPER FUNCTIONS (OPTIONAL)
-- ============================================

-- Function to mark complaint as viewed
CREATE OR REPLACE FUNCTION mark_complaint_as_viewed(complaint_id INTEGER)
RETURNS VOID AS $$
BEGIN
    UPDATE complaints
    SET is_viewed = TRUE,
        viewed_at = NOW()
    WHERE id = complaint_id;
END;
$$ LANGUAGE plpgsql;

-- Function to mark SOS alert as viewed
CREATE OR REPLACE FUNCTION mark_sos_alert_as_viewed(alert_id INTEGER)
RETURNS VOID AS $$
BEGIN
    UPDATE sos_alerts
    SET is_viewed = TRUE,
        viewed_at = NOW()
    WHERE id = alert_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- SUMMARY
-- ============================================

RAISE NOTICE '==========================================';
RAISE NOTICE 'Migration completed successfully!';
RAISE NOTICE 'Added columns:';
RAISE NOTICE '  - complaints.is_viewed';
RAISE NOTICE '  - complaints.viewed_at';
RAISE NOTICE '  - sos_alerts.is_viewed';
RAISE NOTICE '  - sos_alerts.viewed_at';
RAISE NOTICE '';
RAISE NOTICE 'Created indexes:';
RAISE NOTICE '  - idx_complaints_is_viewed';
RAISE NOTICE '  - idx_sos_alerts_is_viewed';
RAISE NOTICE '';
RAISE NOTICE 'Created functions:';
RAISE NOTICE '  - mark_complaint_as_viewed(complaint_id)';
RAISE NOTICE '  - mark_sos_alert_as_viewed(alert_id)';
RAISE NOTICE '==========================================';
