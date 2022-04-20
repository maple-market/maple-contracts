module.exports = async function ({ getNamedAccounts, deployments, network }) {
  if (network.live) {
    return
  }

  const { deployer } = await getNamedAccounts()
  const { deploy } = deployments

  await deploy('MockItem', {
    from: deployer,
    log: true,
  })

  await deploy('MockJewel', {
    from: deployer,
    log: true,
  })
}

module.exports.tags = ['mocks']
