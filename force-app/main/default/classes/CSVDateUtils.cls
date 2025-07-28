public with sharing class CSVDateUtils {
    /**
     * Parses a date string in either 'YYYY-MM-DD' or 'DD/MM/YY' (optionally with 'T00:00:00')
     * and returns a Salesforce Date object.
     * Falls back to today's date if parsing fails.
     *
     * @param response The input date string.
     * @return A valid Date object.
     */
    public static Date manageDateFormat(String response) {
        if (String.isBlank(response)) return System.today();

        response = response.trim();
        response = response.substringBefore('T'); // Remove time if present

        // --- Try parsing 'YYYY-MM-DD' ---
        if (response.contains('-')) {
            List<String> parts = response.split('-');
            if (parts.size() == 3 &&
                isNumeric(parts[0]) && isNumeric(parts[1]) && isNumeric(parts[2])) {

                Integer year = Integer.valueOf(parts[0]);
                Integer month = Integer.valueOf(parts[1]);
                Integer day = Integer.valueOf(parts[2]);

                if (isValidDate(year, month, day)) {
                    return Date.newInstance(year, month, day);
                }
            }
        }

        // --- Try parsing 'DD/MM/YY' ---
        if (response.contains('/')) {
            List<String> parts = response.split('/');
            if (parts.size() == 3 &&
                isNumeric(parts[0]) && isNumeric(parts[1]) && isNumeric(parts[2])) {

                Integer day = Integer.valueOf(parts[0]);
                Integer month = Integer.valueOf(parts[1]);
                Integer year = 2000 + Integer.valueOf(parts[2]); // Assume 21st century

                if (isValidDate(year, month, day)) {
                    return Date.newInstance(year, month, day);
                }
            }
        }

        // --- If all parsing fails, fallback ---
        return System.today();
    }

    /**
     * Checks if a string is a valid numeric value.
     */
    public static Boolean isNumeric(String str) {
        if (String.isBlank(str)) return false;
        try {
            Decimal.valueOf(str);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Validates that the given year, month, and day form a valid date.
     */
    public static Boolean isValidDate(Integer y, Integer m, Integer d) {
        try {
            Date test = Date.newInstance(y, m, d);
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}