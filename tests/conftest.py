from operator import imod
import pytest
from web3 import Web3


# works like a static variables
@pytest.fixture
def amount_staked():
    return(Web3.toWei(1, "ether"))
