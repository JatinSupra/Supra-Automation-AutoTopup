module your_address::high_threshold_auto {
    use supra_framework::coin;
    use supra_framework::supra_coin::SupraCoin;
    use supra_framework::event;
    use std::signer;

    /// Error codes
    const E_INSUFFICIENT_BALANCE: u64 = 1;
    const E_TARGET_NOT_REGISTERED: u64 = 2;

    /// Event emitted when a top-up occurs
    #[event]
    struct HighThresholdTopUpEvent has drop, store {
        deployer: address,
        target: address,
        amount_transferred: u64,
        target_balance_before: u64,
        target_balance_after: u64,
        threshold_used: u64,
        deployer_balance_after: u64,
    }

    /// Main automation function: Tops up 50 SUPRA when target drops below 600 SUPRA
    /// This function will be called by Supra's automation system
    public entry fun high_threshold_topup(
        deployer: &signer,
        target: address,
    ) {
        // Fixed thresholds (in micro-SUPRA: 1 SUPRA = 1,000,000 micro-SUPRA)
        let threshold = 600_000_000; // 600 SUPRA
        let topup_amount = 50_000_000; // 50 SUPRA
        
        // Skip if target is not registered for SupraCoin
        if (!coin::is_account_registered<SupraCoin>(target)) {
            return
        };
        
        // Check target wallet balance
        let target_balance = coin::balance<SupraCoin>(target);
        
        // Only proceed if target balance is below threshold
        if (target_balance < threshold) {
            let deployer_address = signer::address_of(deployer);
            let deployer_balance = coin::balance<SupraCoin>(deployer_address);
            
            // Ensure deployer has sufficient balance
            assert!(deployer_balance >= topup_amount, E_INSUFFICIENT_BALANCE);
            
            // Perform the transfer
            coin::transfer<SupraCoin>(deployer, target, topup_amount);
            
            // Get updated balances for the event
            let target_balance_after = coin::balance<SupraCoin>(target);
            let deployer_balance_after = coin::balance<SupraCoin>(deployer_address);
            
            // Emit event for tracking
            event::emit(HighThresholdTopUpEvent {
                deployer: deployer_address,
                target,
                amount_transferred: topup_amount,
                target_balance_before: target_balance,
                target_balance_after,
                threshold_used: threshold,
                deployer_balance_after,
            });
        }
    }

    /// View function to check if top-up will trigger
    #[view]
    public fun will_topup_trigger(target: address): bool {
        if (!coin::is_account_registered<SupraCoin>(target)) {
            return false
        };
        let threshold = 600_000_000; // 600 SUPRA in micro-SUPRA
        let target_balance = coin::balance<SupraCoin>(target);
        target_balance < threshold
    }

    /// View function to get target balance in SUPRA (not micro-SUPRA)
    #[view]
    public fun get_target_balance_supra(target: address): u64 {
        if (!coin::is_account_registered<SupraCoin>(target)) {
            return 0
        };
        let balance_micro = coin::balance<SupraCoin>(target);
        balance_micro / 1_000_000
    }

    /// View function to get deployer balance in SUPRA
    #[view]
    public fun get_deployer_balance_supra(deployer: address): u64 {
        if (!coin::is_account_registered<SupraCoin>(deployer)) {
            return 0
        };
        let balance_micro = coin::balance<SupraCoin>(deployer);
        balance_micro / 1_000_000
    }

    /// View function to check how much SUPRA is needed to reach threshold
    #[view]
    public fun supra_needed_to_reach_threshold(target: address): u64 {
        if (!coin::is_account_registered<SupraCoin>(target)) {
            return 600 // Full threshold needed
        };
        let threshold = 600_000_000; // 600 SUPRA in micro-SUPRA
        let target_balance = coin::balance<SupraCoin>(target);
        
        if (target_balance >= threshold) {
            0 // No top-up needed
        } else {
            (threshold - target_balance) / 1_000_000
        }
    }

    /// View function to check if deployer can afford the top-up
    #[view]
    public fun can_deployer_afford_topup(deployer: address): bool {
        if (!coin::is_account_registered<SupraCoin>(deployer)) {
            return false
        };
        let topup_amount = 50_000_000; // 50 SUPRA in micro-SUPRA
        let deployer_balance = coin::balance<SupraCoin>(deployer);
        deployer_balance >= topup_amount
    }

    /// View function for complete status check
    #[view]
    public fun get_automation_status(deployer: address, target: address): (bool, u64, u64, u64) {
        let will_trigger = will_topup_trigger(target);
        let target_balance_supra = get_target_balance_supra(target);
        let deployer_balance_supra = get_deployer_balance_supra(deployer);
        let supra_needed = supra_needed_to_reach_threshold(target);
        
        (will_trigger, target_balance_supra, deployer_balance_supra, supra_needed)
    }

    #[test_only]
    use supra_framework::account;
    use std::debug::print;
    use std::string::utf8;

    #[test(supra_framework = @supra_framework, deployer = @0x123, target = @0x456)]
    public entry fun test_high_threshold_automation(
        supra_framework: &signer,
        deployer: &signer,
        target: &signer
    ) {
        // Setup accounts
        let deployer_addr = signer::address_of(deployer);
        let target_addr = signer::address_of(target);
        
        account::create_account_for_test(deployer_addr);
        account::create_account_for_test(target_addr);
        
        // Initialize coin for test
        let (burn_cap, mint_cap) = supra_framework::supra_coin::initialize_for_test(supra_framework);
        
        // Register coin stores
        coin::register<SupraCoin>(deployer);
        coin::register<SupraCoin>(target);
        
        // Give deployer 1000 SUPRA and target 500 SUPRA (simulating real scenario)
        supra_framework::supra_coin::mint(supra_framework, deployer_addr, 1_000_000_000); // 1000 SUPRA
        supra_framework::supra_coin::mint(supra_framework, target_addr, 500_000_000);     // 500 SUPRA
        
        print(&utf8(b"=== BEFORE AUTOMATION ==="));
        print(&utf8(b"Target balance (SUPRA):"));
        print(&get_target_balance_supra(target_addr));
        print(&utf8(b"Deployer balance (SUPRA):"));
        print(&get_deployer_balance_supra(deployer_addr));
        print(&utf8(b"Will trigger?"));
        print(&will_topup_trigger(target_addr));
        
        // Test: target has 500 SUPRA < 600 SUPRA threshold, so top-up should occur
        high_threshold_topup(deployer, target_addr);
        
        print(&utf8(b"=== AFTER AUTOMATION ==="));
        print(&utf8(b"Target balance (SUPRA):"));
        print(&get_target_balance_supra(target_addr));
        print(&utf8(b"Deployer balance (SUPRA):"));
        print(&get_deployer_balance_supra(deployer_addr));
        print(&utf8(b"Will trigger again?"));
        print(&will_topup_trigger(target_addr));
        
        // Verify the balances
        assert!(get_target_balance_supra(target_addr) == 550, 1); // 500 + 50 = 550 SUPRA
        assert!(get_deployer_balance_supra(deployer_addr) == 950, 2); // 1000 - 50 = 950 SUPRA
        
        // Target still has 550 < 600, so automation would trigger again
        assert!(will_topup_trigger(target_addr), 3); // Should still trigger (550 < 600)
        
        // Run automation again to reach above threshold
        high_threshold_topup(deployer, target_addr);
        
        print(&utf8(b"=== AFTER SECOND AUTOMATION ==="));
        print(&utf8(b"Target balance (SUPRA):"));
        print(&get_target_balance_supra(target_addr));
        
        // Now target should have 600 SUPRA and not trigger anymore
        assert!(get_target_balance_supra(target_addr) == 600, 4); // 550 + 50 = 600 SUPRA
        assert!(!will_topup_trigger(target_addr), 5); // Should NOT trigger (600 >= 600)
        
        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }
}