import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals, assertStringIncludes } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// Helper to convert STX amount to micro-STX
function stx(amount: number): number {
  return amount * 1000000;
}

// Helper to get error codes
const errorCodes = {
  ownerOnly: 100,
  notAuthorized: 101,
  assetExists: 102,
  assetNotFound: 103,
  insufficientFunds: 104,
  invalidParameters: 105,
  strategyExists: 106,
  strategyNotFound: 107,
  proposalExists: 108,
  proposalNotFound: 109,
  voteAlreadyCast: 110,
  votingPeriodEnded: 111,
  votingPeriodActive: 112,
  proposalNotApproved: 113,
  proposalAlreadyExecuted: 114,
  allocationExceeded: 115,
  riskExceeded: 116,
  scheduleExists: 117,
  scheduleNotFound: 118
};

// Convert error code to error string from Clarity
function getError(code: number): string {
  return `(err u${code})`;
}

Clarinet.test({
  name: "Initialization Test - Contract owner can initialize the treasury",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const daoToken = `${deployer.address}.governance-token`;
    const guardian = accounts.get('wallet_1')!;
    
    const block = chain.mineBlock([
      Tx.contractCall(
        'dao-treasury',
        'initialize',
        [
          types.ascii('Test DAO Treasury'),
          types.principal(daoToken),
          types.principal(guardian.address)
        ],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    assertEquals(block.receipts[0].result, '(ok true)');
  }
});

Clarinet.test({
  name: "Only owner can initialize the treasury",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const nonOwner = accounts.get('wallet_1')!;
    const daoToken = `${accounts.get('deployer')!.address}.governance-token`;
    const guardian = accounts.get('wallet_2')!;
    
    const block = chain.mineBlock([
      Tx.contractCall(
        'dao-treasury',
        'initialize',
        [
          types.ascii('Test DAO Treasury'),
          types.principal(daoToken),
          types.principal(guardian.address)
        ],
        nonOwner.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    assertEquals(block.receipts[0].result, getError(errorCodes.ownerOnly));
  }
});

Clarinet.test({
  name: "Asset Registration - Contract owner can register a new asset",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const daoToken = `${deployer.address}.governance-token`;
    const guardian = accounts.get('wallet_1')!;
    const assetOracle = accounts.get('wallet_2')!;
    
    // First initialize the treasury
    let block = chain.mineBlock([
      Tx.contractCall(
        'dao-treasury',
        'initialize',
        [
          types.ascii('Test DAO Treasury'),
          types.principal(daoToken),
          types.principal(guardian.address)
        ],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts[0].result, '(ok true)');
    
    // Now register an asset
    block = chain.mineBlock([
      Tx.contractCall(
        'dao-treasury',
        'register-asset',
        [
          types.ascii('btc'),
          types.ascii('Bitcoin'),
          types.ascii('btc'),
          types.none(),
          types.principal(assetOracle.address),
          types.uint(8),
          types.uint(8)
        ],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    assertEquals(block.receipts[0].result, '(ok "btc")');
    
    // Verify asset was registered
    const assetResponse = chain.callReadOnlyFn(
      'dao-treasury',
      'get-asset',
      [types.ascii('btc')],
      deployer.address
    );
    
    assertStringIncludes(assetResponse.result, '{name: "Bitcoin"');
    assertStringIncludes(assetResponse.result, 'token-type: "btc"');
    assertStringIncludes(assetResponse.result, 'risk-score: u8');
  }
});

Clarinet.test({
  name: "Only owner can register assets",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const nonOwner = accounts.get('wallet_1')!;
    const daoToken = `${deployer.address}.governance-token`;
    const guardian = accounts.get('wallet_2')!;
    const assetOracle = accounts.get('wallet_3')!;
    
    // First initialize the treasury
    let block = chain.mineBlock([
      Tx.contractCall(
        'dao-treasury',
        'initialize',
        [
          types.ascii('Test DAO Treasury'),
          types.principal(daoToken),
          types.principal(guardian.address)
        ],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts[0].result, '(ok true)');
    
    // Try to register an asset as non-owner
    block = chain.mineBlock([
      Tx.contractCall(
        'dao-treasury',
        'register-asset',
        [
          types.ascii('btc'),
          types.ascii('Bitcoin'),
          types.ascii('btc'),
          types.none(),
          types.principal(assetOracle.address),
          types.uint(8),
          types.uint(8)
        ],
        nonOwner.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    assertEquals(block.receipts[0].result, getError(errorCodes.ownerOnly));
  }
});

Clarinet.test({
  name: "Cannot register the same asset twice",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const daoToken = `${deployer.address}.governance-token`;
    const guardian = accounts.get('wallet_1')!;
    const assetOracle = accounts.get('wallet_2')!;
    
    // First initialize the treasury
    let block = chain.mineBlock([
      Tx.contractCall(
        'dao-treasury',
        'initialize',
        [
          types.ascii('Test DAO Treasury'),
          types.principal(daoToken),
          types.principal(guardian.address)
        ],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts[0].result, '(ok true)');
    
    // Register an asset
    block = chain.mineBlock([
      Tx.contractCall(
        'dao-treasury',
        'register-asset',
        [
          types.ascii('btc'),
          types.ascii('Bitcoin'),
          types.ascii('btc'),
          types.none(),
          types.principal(assetOracle.address),
          types.uint(8),
          types.uint(8)
        ],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts[0].result, '(ok "btc")');
    
    // Try to register the same asset again
    block = chain.mineBlock([
      Tx.contractCall(
        'dao-treasury',
        'register-asset',
        [
          types.ascii('btc'),
          types.ascii('Bitcoin Again'),
          types.ascii('btc'),
          types.none(),
          types.principal(assetOracle.address),
          types.uint(7),
          types.uint(8)
        ],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    assertEquals(block.receipts[0].result, getError(errorCodes.assetExists));
  }
});

Clarinet.test({
  name: "Price Oracle - Only authorized oracle can update asset price",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const daoToken = `${deployer.address}.governance-token`;
    const guardian = accounts.get('wallet_1')!;
    const assetOracle = accounts.get('wallet_2')!;
    const unauthorizedOracle = accounts.get('wallet_3')!;
    
    // Initialize the treasury
    let block = chain.mineBlock([
      Tx.contractCall(
        'dao-treasury',
        'initialize',
        [
          types.ascii('Test DAO Treasury'),
          types.principal(daoToken),
          types.principal(guardian.address)
        ],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts[0].result, '(ok true)');
    
    // Register an asset
    block = chain.mineBlock([
      Tx.contractCall(
        'dao-treasury',
        'register-asset',
        [
          types.ascii('btc'),
          types.ascii('Bitcoin'),
          types.ascii('btc'),
          types.none(),
          types.principal(assetOracle.address),
          types.uint(8),
          types.uint(8)
        ],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts[0].result, '(ok "btc")');
    
    // Update price from unauthorized oracle
    block = chain.mineBlock([
      Tx.contractCall(
        'dao-treasury',
        'update-asset-price',
        [
          types.ascii('btc'),
          types.uint(30000 * 1000000) // $30,000 price
        ],
        unauthorizedOracle.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    assertEquals(block.receipts[0].result, getError(errorCodes.notAuthorized));
    
    // Update price from authorized oracle
    block = chain.mineBlock([
      Tx.contractCall(
        'dao-treasury',
        'update-asset-price',
        [
          types.ascii('btc'),
          types.uint(30000 * 1000000) // $30,000 price
        ],
        assetOracle.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    assertEquals(block.receipts[0].result, '(ok true)');
    
    // Verify price was updated
    const assetResponse = chain.callReadOnlyFn(
      'dao-treasury',
      'get-asset',
      [types.ascii('btc')],
      deployer.address
    );
    
    assertStringIncludes(assetResponse.result, 'current-price: u30000000000');
  }
});
