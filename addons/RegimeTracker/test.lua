--[[
Test script for RegimeTracker addon
This script helps test the basic functionality without needing to actually kill mobs
]]

-- Test function to simulate regime progress
function test_regime_tracking()
    print("=== RegimeTracker Test Script ===")
    print("This script tests the basic functionality of the RegimeTracker addon")
    print()
    
    -- Test database connection
    print("Testing database connection...")
    local infobar_path = windower.addon_path..'/../InfoBar/database.db'
    if windower.file_exists(infobar_path) then
        print("✓ InfoBar database found")
        
        -- Test database query
        local db = sqlite3.open(infobar_path)
        if db and db:isopen() then
            print("✓ Database connection successful")
            
            -- Test a simple query
            local test_query = 'SELECT COUNT(*) FROM "monster" LIMIT 1'
            for count in db:urows(test_query) do
                print("✓ Database query successful - Monster count: " .. count)
            end
            
            db:close()
        else
            print("✗ Database connection failed")
        end
    else
        print("✗ InfoBar database not found")
        print("  Make sure the InfoBar addon is installed")
    end
    
    print()
    print("=== Test Commands ===")
    print("Use these commands to test the addon:")
    print("//regime set \"Goblin\" 4")
    print("//regime status")
    print("//regime clear")
    print("//regime help")
    print()
    print("=== Expected Behavior ===")
    print("1. Set a regime with //regime set")
    print("2. Kill mobs of the specified family")
    print("3. See progress messages after each kill")
    print("4. Get completion message when target is reached")
    print()
    print("Test completed!")
end

-- Run the test
test_regime_tracking()
