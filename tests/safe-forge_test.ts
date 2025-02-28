import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// [Previous test cases remain unchanged]

Clarinet.test({
  name: "Test template versioning",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const templateId = 1;
    const templateName = "Test Template";
    const codeHash = "0x0123456789abcdef";
    
    let block = chain.mineBlock([
      Tx.contractCall("safe-forge-core", "add-template",
        [types.uint(templateId), types.ascii(templateName), types.ascii("validation criteria")],
        deployer.address
      ),
      Tx.contractCall("safe-forge-core", "update-template-version",
        [types.uint(templateId), types.buff(32, codeHash), types.ascii("Version update")],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts[0].result.expectOk(), true);
    assertEquals(block.receipts[1].result.expectOk(), true);
    
    let template = chain.callReadOnlyFn(
      "safe-forge-core",
      "get-template",
      [types.uint(templateId)],
      deployer.address
    );
    
    assertEquals(template.result.expectSome().version, 2);
  },
});

Clarinet.test({
  name: "Test deployment tracking",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const templateId = 1;
    const contractId = 1;
    
    let block = chain.mineBlock([
      Tx.contractCall("safe-forge-deployer", "deploy-contract",
        [types.uint(contractId), types.uint(templateId), types.ascii("test config")],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts[0].result.expectOk(), true);
  },
});
