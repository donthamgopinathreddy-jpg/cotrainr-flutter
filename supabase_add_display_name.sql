-- ============================================
-- Add display_name column to profiles table
-- ============================================
-- display_name = first_name + ' ' + last_name
-- ============================================

-- Add display_name column if it doesn't exist
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS display_name TEXT;

-- Create a function to automatically update display_name when first_name or last_name changes
CREATE OR REPLACE FUNCTION public.update_display_name()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Combine first_name and last_name
  NEW.display_name := TRIM(
    COALESCE(NEW.first_name, '') || ' ' || COALESCE(NEW.last_name, '')
  );
  
  -- If display_name is just whitespace, set it to NULL
  IF NEW.display_name = '' OR NEW.display_name = ' ' THEN
    NEW.display_name := NULL;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger to auto-update display_name
DROP TRIGGER IF EXISTS trigger_update_display_name ON public.profiles;
CREATE TRIGGER trigger_update_display_name
  BEFORE INSERT OR UPDATE OF first_name, last_name ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.update_display_name();

-- Update existing records to have display_name
UPDATE public.profiles
SET display_name = TRIM(
  COALESCE(first_name, '') || ' ' || COALESCE(last_name, '')
)
WHERE display_name IS NULL 
  AND (first_name IS NOT NULL OR last_name IS NOT NULL);

-- Add comment for documentation
COMMENT ON COLUMN public.profiles.display_name IS 'Full display name (first_name + last_name)';














