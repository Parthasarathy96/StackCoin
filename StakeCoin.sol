    //SPDX-License-Identifier: MIT
    pragma solidity ^0.8.0;

    import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.1/contracts/access/Ownable.sol";
    import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.1/contracts/utils/Context.sol";

    contract stakeToke is Ownable{
    //Events
        event TransferE(address indexed from, address indexed to, uint tokens);
        event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
        event Stake_List(address indexed user, uint amount, uint index, uint timestamp);

    //Token Profile
        string public constant name = "StakeCoin";
        string public constant Symbol = "STC";
        uint8 public constant decimals = 18;


    //Token Holder
        mapping(address => uint) balances;
        mapping(address => mapping(address => uint)) allowed;
        uint totalSupply;

    //Stake
        struct stk_amt{
            uint amt;
            uint timestamp;   
        }        

        uint stk_time;
        address[] internal stakeholders;
        mapping(address => stk_amt)internal stak;
        mapping(address => uint) internal stakes;
        mapping(address => uint) internal rewards;

        constructor(uint total){
            address owner = msg.sender;
            totalSupply = total;
            balances[msg.sender] = totalSupply;
        }

        
        function balanceof(address holder) public view returns(uint) {
            return balances[holder];
        }

        function holderBalanceof() public view returns(uint) {
            return balances[msg.sender];
        }

        function Transfer(address to, uint tokens) public returns (bool) {
            require(tokens <= balances[msg.sender], "Low Balance");
            balances[msg.sender] = balances[msg.sender] - tokens;
            balances[to] = balances[to] + tokens;
            emit TransferE (msg.sender, to, tokens); 
            return true;
        }

        function Approve(address Token_holder, uint NTokens) public returns (bool){
            allowed[msg.sender][Token_holder] = NTokens;
            emit Approval(msg.sender, Token_holder, NTokens);
            return true;
        }

        function transferFrom(address holder, address buyer, uint numTokens) public returns (bool) {
            require(numTokens <= balances[holder]);
            require(numTokens <= allowed[holder][msg.sender]);
            balances[holder] -= numTokens;
            allowed[holder][msg.sender] -= numTokens;
            balances[buyer] += numTokens;
            emit TransferE(holder, buyer, numTokens);
            return true;
        }

        function checkStakehldr(address Stkhldr_address) public view returns(bool, uint) {
            for (uint s = 0; s < stakeholders.length; s += 1){
            if (Stkhldr_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
        }

        function addStakeholder(address _stakeholder, uint Stake_amount) public {
        require(Stake_amount > 0, "Stake amount cannot be zero");
        require(balances[msg.sender] >= Stake_amount, "Low Balance" );

        (bool _isStakeholder, ) = checkStakehldr(_stakeholder);
        if(!_isStakeholder) stakeholders.push(_stakeholder);
        }

        function rmvStakeholder(address Sholder) public {
        (bool _isStakeholder, uint s) = checkStakehldr(Sholder);
         if(_isStakeholder){
           stakeholders[s] = stakeholders[stakeholders.length - 1];
           stakeholders.pop();
       }

        }

        function holderReward(address _stakehldr) public view  onlyOwner returns(uint)
        {
       return rewards[_stakehldr];
        }

        function MyReward() public view returns(uint)
        {
       return rewards[msg.sender];
        }


        function adder(uint x, uint y) internal pure returns(uint){
            return x + y;
        } 
        
        function sub(uint x, uint y) internal pure returns(uint){
            return x - y;
        } 

        
        function totalRewards() public view returns(uint){
        uint _totalRewards = 0;
       for (uint s = 0; s < stakeholders.length; s += 1){
           _totalRewards = adder(_totalRewards,rewards[stakeholders[s]]);
        }
       return _totalRewards;
        }

        function startStake() public onlyOwner returns(uint){
            stk_time = block.timestamp;
            return stk_time;

        }

        function createStk(uint _stake) public {
        
            if(stakes[msg.sender] == 0) addStakeholder(msg.sender, _stake);
            
            stak[msg.sender].amt = adder(stak[msg.sender].amt,_stake);
                stak[msg.sender].timestamp = block.timestamp;
        }

        function rmvstk(uint stk) public{
            stakes[msg.sender] = sub(stakes[msg.sender],stk);
            if(stakes[msg.sender] == 0) rmvStakeholder(msg.sender);
        }

        function mulDiv(uint _percent, uint _amount, uint z) internal pure returns(uint){
            return _percent * _amount/z;
        }
    
         function calculateReward(address holder) public view onlyOwner returns(uint )
       {
           uint period = (stak[holder].timestamp - stk_time) / 60 / 60 / 24;
           //uint amt = stak[msg.sender].amt;
           uint reward;
           if(period >= 30 || period < 60){
               reward = mulDiv (15, stak[holder].amt, 10^8);
           }else if(period >= 60 || period < 90){
               reward = mulDiv (30, stak[holder].amt, 10^8);
           }else if(period >= 90){
               reward = mulDiv (45, stak[holder].amt, 10^8);
           }
           return reward;
       }

        function distributeRewards() public {
        for (uint s = 0; s < stakeholders.length; s += 1){
           address stakeholder = stakeholders[s];
           uint reward = calculateReward(stakeholder);
           rewards[stakeholder] = adder(rewards[stakeholder], reward);
            }
        }

         function withdrawReward() public {
         uint reward = rewards[msg.sender];
         balances[msg.sender] += reward;
         rewards[msg.sender] = 0;
         
        }
    }
