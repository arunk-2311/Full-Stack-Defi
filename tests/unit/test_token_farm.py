
import pytest
from brownie import network, exceptions
from scripts.helpful_scripts import LOCAL_BLOCKCHAIN_ENVIRONMENTS, get_account, get_contract, INITIAL_VALUE
from scripts.deploy import deploy_token_farm_and_dapp_token


def test_set_price_feed():
    # arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("only for local testing!")

    account = get_account()
    non_owner = get_account(1)

    token_farm, dapp_token = deploy_token_farm_and_dapp_token()
    price_feed_address = get_contract("eth_usd_price_feed")
    # Act

    # deploying setPriceFeed is already done in stake tokens via allowed_tokens

    # token_farm.setPriceFeed(
    #    dapp_token, price_feed_address, {"from": account})
    # Assert
    assert token_farm.tokenPriceFeedMapping(
        dapp_token.address) == price_feed_address

    with pytest.raises(exceptions.VirtualMachineError):
        # it should be not possible,so the test will pass
        token_farm.setPriceFeed(
            dapp_token, price_feed_address, {"from": non_owner})


def test_stake_tokens(amount_staked):
    # arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("only for local testing!")

    account = get_account()
    token_farm, dapp_token = deploy_token_farm_and_dapp_token()

    # Act
    dapp_token.approve(token_farm.address, amount_staked, {"from": account})
    token_farm.stakeTokens(
        amount_staked, dapp_token.address, {"from": account})
    assert (
        token_farm.stakingBalance(dapp_token.address, account) == amount_staked
    )

    assert token_farm.uniqueTokensStaked(account) == 1
    assert token_farm.stakers(0) == account

    return token_farm, dapp_token


def test_issue_tokens(amount_staked):
    # arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("only for local testing!")

    account = get_account()
    token_farm, dapp_token = test_stake_tokens(amount_staked)
    starting_balance = dapp_token.balanceOf(account)

    # Act
    token_farm.issueTokens({"from": account})

    # Assert
    assert (
        # we are staking 1 dapp which we are claiming to have a value of 1 eth
        # we should get 2000 dapp tokens as reward,because while deploying the tokens in mock deploy ,we assumed 1 eth = 2000 dapp tokens
        dapp_token.balanceOf(account) == starting_balance + INITIAL_VALUE
    )
