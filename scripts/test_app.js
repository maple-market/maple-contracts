const { getNamedAccounts, ethers } = require('hardhat')
const ERC721ABI = require('../abis/ERC721.json')

async function main() {
  const { deployer } = await getNamedAccounts()
  const signer = await ethers.getSigner(deployer)
  const AccountFactory = await ethers.getContract('AccountFactory', signer)
  const MapleMarket = await ethers.getContract('MapleMarket', signer)

  // step1: create account if necessary
  const hasAccount = await AccountFactory.hasAccount(signer.address)
  if (!hasAccount) {
    const tx = await AccountFactory.createAccountWithWhitelist(
      [MapleMarket.address],
      { value: ethers.utils.parseEther('1') },
    )
    await tx.wait()
  }

  const account = await AccountFactory.accounts(signer.address)
  console.log(`account: ${account}`)
}

main()
  .then(() => process.exit(0))
  .catch((e) => {
    console.log(e)
    process.exit(1)
  })
