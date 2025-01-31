import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure owner can set permissions",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const user1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("safe-forge-core", "set-permissions", 
        [types.principal(user1.address), types.bool(true), types.bool(false)],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts[0].result.expectOk(), true);
  },
});

Clarinet.test({
  name: "Ensure only authorized users can add templates",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const user1 = accounts.get("wallet_1")!;
    const templateId = 1;
    const templateName = "Test Template";
    
    let block = chain.mineBlock([
      Tx.contractCall("safe-forge-core", "add-template",
        [types.uint(templateId), types.ascii(templateName)],
        user1.address
      )
    ]);
    
    assertEquals(block.receipts[0].result.expectErr(), "u102");
  },
});
