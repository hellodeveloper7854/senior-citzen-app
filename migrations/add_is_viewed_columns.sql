-- Migration: Add is_viewed columns to complaints and sos_alerts tables
-- Created: 2025-01-24
-- Description: Add tracking for viewed/unviewed notifications

-- Add is_viewed column to complaints table
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

        RAISE NOTICE 'Added is_viewed column to complaints table';
    ELSE
        RAISE NOTICE 'is_viewed column already exists in complaints table';
    END IF;
END
$$;

-- Add is_viewed column to sos_alerts table
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

        RAISE NOTICE 'Added is_viewed column to sos_alerts table';
    ELSE
        RAISE NOTICE 'is_viewed column already exists in sos_alerts table';
    END IF;
END
$$;

-- Verify the columns were added successfully
SELECT
    table_name,
    column_name,
    data_type,
    column_default
FROM
    information_schema.columns
WHERE
    table_name IN ('complaints', 'sos_alerts')
    AND column_name = 'is_viewed'
ORDER BY
    table_name;
