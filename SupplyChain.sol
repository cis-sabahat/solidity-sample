pragma solidity ^0.4.25;

contract SupplyChain {

    using SafeMath for uint256;
    using Strings for string;
    
    /*
    *  Events
    */
    event Transfer( 
        string causedby,
        uint8 phase,
        string activity,
        address indexed sender, 
        address indexed receiver, 
        uint256 value,
        string executed,
        uint transID,
        uint256 timestamp,
        uint tokenStart,
        uint tokenEnd
    );

    event CustomerTransfer( 
        address indexed sender, 
        address indexed receiver, 
        uint256 value,
        uint256 timestamp,
        uint tokenStart,
        uint tokenEnd
    );

    event Deposit(
         uint8 value,
    );
    
    
    event currentStatus( 
        
        uint8 phase,
        uint8 activity,
        uint tokenStart,
        uint tokenEnd
    );


    event ActivityDetail (
        string activity,
        uint8 priority,
        address activityOwner,
        string status,
        uint256 timestamp
    );
    
   


    event ActivityClaim(
        uint8 phase, 
        string activity,
        address activityowner,
        uint256 minedABC,
        uint256 plannedPhaseQuantity,
        uint transID
    );
    
  
    
    
    /*
    * Structs
    */
    struct ActivityData  {
        string activity;
        string currentStatus;
        uint8 priority;
        address activityOwner;
        address[] approvers;
    }
    
    struct Activity {}

    struct Transaction {
        address sender;
        address receiver;
        uint256 value;
        bool executed;
    }
    
    struct ResidualRange {
        uint transactionID;
        uint tokenstart;
        uint tokenend;
        
        //uint256 [] tokenRange;
    }
    
     /*
    *  Storage
    */
    mapping(address => uint256) public balances;
    mapping(string => ActivityData) activityData;
    // mapping(uint8 => mapping(uint8 => ActivityData )) sequenceData;
    mapping(uint8 => mapping(uint8 => mapping(uint => Activity))) activityExecutions; // Add transID also in mapping//updated 
    mapping(uint8 => mapping(string => mapping(uint =>mapping(address => string)))) approversStatus;
    mapping() ownerStatus;  
    mapping () transactions;
    mapping() files;
    mapping(uint => ResidualRange) public ResidualTransactions;
              
    
    /*
    *  Modifiers
    */
    modifier isOwner() {
       require(msg.sender == owner);
       _;
    }
 
    modifier approverExists(string memory activity, address approver) {
        
        if(approver == owner) {
            _;
        } else {
            address [] memory approverList;
            exist = false;
            approverList = activityData[activity].approvers; 
            for(uint8 i = 0; i < approverList.length; i++) {
                if(approverList[i] == approver) {
                    exist = true;
                    break;
                }
            }
            require(exist,"This is not a valid approver");
            _;
        }
        
    }
    
    

    
    modifier isActivityActive(string memory activity) 
    {
        
            status = activityData[activity].currentStatus; 
            if(status.compareToIgnoreCase('Active')) {
                    exist = true;
            }
            require(exist,"Activity is not active");
            _;
    }

    modifier notApproved(uint8 phase, string memory activity,uint transId, address approver) {
        require((approversStatus[phase][activity][transId][approver]).compareToIgnoreCase(''));
        _;
    }
    
    modifier checkStatus(string memory status) {
        require(status.compareToIgnoreCase("pending"));
        _;
    }


    modifier isApproved(uint8 phase, string memory activity,uint transId) {
        if((ownerStatus[phase][activity][transId][msg.sender]).compareToIgnoreCase("accept")) {
            _;
        } else {
            address [] memory approverList;
            approverList = activityData[activity].approvers; 
            for(uint8 i = 0; i < approverList.length; i++) {
                require((approversStatus[phase][activity][transId][approverList[i]]).compareToIgnoreCase("accept"),"All approvers not approved");
              
            }
            _;
        }
    }
    
    string[] ActivityList;
    address [] approversAddress;  
}

contract ABC is ABCStruct {  
     address public BDGET_WALLET;
     uint public  tokenStart;
     uint  public tokenEnd;
     uint [] public ResidualList;
     

      function activityExist(string memory _activityName) public view returns (bool)
       {    
            bool isPresent=false;
            for (uint i=0;i<ActivityList.length;i++)
            {    
                string memory preActivity =ActivityList[i];           
                if (_activityName.compareToIgnoreCase(preActivity)){
                    isPresent=true;
                }                
            }
            return isPresent;
        } 

    function addActivity( 
        string memory _activity,
        uint8 _priority,
        address _activityOwner,
        address[] memory _approvers
    )
        public 
        isOwner()
    {   
        string memory _statusActivity = "Active";
        if(!(activityExist(_activity))){

        ActivityData storage activityDataTemp = activityData[_activity];
           activityDataTemp.activity = _activity;
           ActivityList.push(_activity);
        
           //emit the event
           for(uint8 i = 0; i < _approvers.length; i++) {
               emit ActivityApprover(_activity, _approvers[i], now);
           }
           emit ActivityDetail(_activity, _priority, _activityOwner, "Active", now);
        }
       else{ 
         emit ActivityDetail(_activity, 0, msg.sender
         , _statusActivity, now);
    }
    }
    
    /// @dev Allows to update activity status.
    /// @param _priority of the activity.
    /// @param _activity Name of the activity.
    /// @param _activity owner who can claim.
    function updateActivity( 
        string memory _activity,
        uint8 _priority, 
        address _activityOwnwer,
        string memory _status
    )
        public 
        isActivityActive(_activity)
    {   
    if (balances[_activityOwnwer] == 0)
    {  
            ActivityData storage activityDataTemp = activityData[_activity];
        
            activityDataTemp.currentStatus = _status;
            ActivityList.push(_activity);
            emit ActivityDetail(_activity, _priority, _activityOwnwer, _status, now);
    } 
   
    }
 
    /// @dev Allows to execute the activity.
    /// @param _phase Phase of the activity.
    /// @param _activity Name of the activity.
    /// @param _minedABC Number of ABC to be executed.
    function claimActivity(
        uint8 _phase, 
        string memory _activity, 
        uint256 _minedABC,// Add plannedPhaseQty and transID for Events
        uint256 _plannedPhaseQuantity,
        uint _transID,
        address _activityOwnwer
    ) 
        public
        isActivityActive(_activity)
     
    {    
        if (_plannedPhaseQuantity >= _minedABC){
               if( activityData[_activity].activityOwner == _activityOwnwer ) {
                    uint8 priority = activityData[_activity].priority;
                    Activity storage activity = activityExecutions[_phase][priority][_transID];
                    activity.transID=_transID; 

                }
        emit  ActivityClaim(_phase, _activity,activityData[_activity].activityOwner, _minedABC,_plannedPhaseQuantity,_transID);

         } 
    } 


    /// @dev Allows to confirm the activity by activity approvers.
    /// @param _phase Phase of the activity.
    /// @param _activity Name of the activity.
    /// @param _approver Approver address of the activity.
    /// @param _status Status of the approver either "accept" or "reject".
    function setApproverStatus(
        uint8 _phase, 
        string memory _activity, 
        address _approver, 
        string  memory _status,
        uint256 _minedABC,// minned ABC //upadted
        uint _transID
        // add transID so that approvers can approve valid [phase][activity][transID] //updated
    ) 
        public
        isActivityActive(_activity)
        approverExists(_activity, _approver)
    {   
       
        if(_approver == owner) {
            require((ownerStatus[_phase][_activity][_transID][_approver]).compareToIgnoreCase(''),"Allready status set");
            ownerStatus[_phase][_activity][_transID][_approver] = _status;
        } else {
            require((approversStatus[_phase][_activity][_transID][_approver]).compareToIgnoreCase(''),"Allready status set");
            approversStatus[_phase][_activity][_transID][_approver] = _status;
        }

        emit ActivityApproverStatus(_phase, _activity, _approver, _status,_minedABC,_transID, now);
    }
    
    
    /// @dev Allows to transfer token to the activity_owner.
    /// @param _phase Phase of the activity.
    /// @param _activity Name of the activity.
    /// @param _from Sender address.
    /// @param _to Receiver address.
    /// @param _value Number of token to be transfer.
    function transferToken(
        uint8 _phase, 
        string memory _activity, 
        address _from,
        address _to, 
        uint256 _value,
        //Add transID also to check  
        uint _transID,
        uint _startToken,
        uint _endToken

    )
        public
        isOwner()
        isActivityActive(_activity)
        isApproved(_phase, _activity,_transID) // add transID as parameter 
    {
            inputStartToken = _startToken;
            inputEndToken = _endToken;
           phaseValue = _phase;
           activityName = _activity;
           sender = _from;
           receiver = _to;
           value = _value; 
           transID=_transID;
           TransferCausedby= "Normal";    
           transfer();
      
    }
    /// @dev Allows to transfer token to the Residual wallet.
    /// @param _phase Phase of the activity.
    /// @param _activity Name of the activity.
    /// @param _value Number of token to be transfer.

    function ResidualtransferToken(
        uint8 _phase, 
        string memory _activity, 
        uint256 _value,
        address  _from,
        address  _to ,
        uint _startToken,
        uint _endToken
       
    )
        public
        isOwner()
     {
         
                phaseValue = _phase;
                activityName = _activity;
                sender =  _from ;
                receiver =_to;
                value = _value; 
                TransferCausedby= "Residual";
                inputStartToken = _startToken;
                inputEndToken = _endToken;
               
                transfer();
       
    }
   
   /// @dev Allows to transfer token to the activity_owner.
    function transfer()  internal   returns(bool success)  {   
      uint8 priority = 0;
       uint currentStart;
       uint currentEnd;
      // ActivityData memory activity;
       if (balances[sender] >= value && value > 0)
       { 
            if(TransferCausedby.compareToIgnoreCase("Residual"))
            {
                uint tID = ResidualList.length+1;
            ResidualRange storage res = ResidualTransactions[tID];
            res.transactionID = tID;
            res.tokenstart = inputStartToken;
            currentEnd =res.tokenend;
            balances[receiver] = balances[receiver].add(value);
            balances[sender] = balances[sender].sub(value);
            emit ResidualStatus(tID,currentStart,currentEnd);

             }
            else if (TransferCausedby.compareToIgnoreCase("Normal"))
            {
            priority = activityData[activityName].priority;
        
                 
             currentStart = inputStartToken;
             currentEnd = inputEndToken;
        
            //uint8 tempPriority = priority;
            Transaction storage transactionTemp = transactions[phaseValue][activityName][transID];
            Activity storage   myactivity = activityExecutions[phaseValue][priority][transID];
            balances[receiver] = balances[receiver].add(value);
            balances[sender] = balances[sender].sub(value);

            myactivity.status = "done";
            transactionTemp.executed = true;
        
            emit Transfer(TransferCausedby,phaseValue, activityName, sender, receiver, value, "confirmed",transID, now,currentStart,currentEnd);
            // emit Transfer(activityName,"confirmed",currentStart,currentEnd);
             return true;
           
            }
           
        }
        else
        { 
            return false; 
        }
    }
    
    /// @dev Allows to get current status of activity.
    /// @param phase Phase of the activity.
    /// @param priority Priority of the activity.
    
    // function getCurrentTokenStatus(uint8 phase, uint8 priority) public 
    // {
    //     uint256 currentStart = activityUpdate[phase][priority].tokenstart;
    //     uint256 currentEnd = activityUpdate[phase][priority].tokenend;
    
    //     emit currentStatus(phase,priority,currentStart,currentEnd);
    // }

    /// @dev Allows to set the file hash and ipfs password.
    /// @param _phase Phase of the activity.
    /// @param _activity Name of the activity.
    /// @param _fileName Name of the file.
    /// @param _fileHash File hash on the IPFS.
    function setFileHash(
        uint8 _phase, 
        string memory _activity, 
        string memory _fileName,  
        string memory _fileHash
    ) 
        public {
        files[_phase][_activity][_fileName] = _fileHash;
        emit File(_phase, _activity, _fileName, _fileHash, now);
    }

    /// @dev Returns the balance of the given address.
    /// @param _owner Address of the owner.
    /// @return the balance of the given address.
    function balanceOf(address _owner) public view returns(uint256 balance) {
        return balances[_owner];
    }


    /// @dev Returns approvers address of the activity.
    /// @param _activity Activity name.
    /// @return approvers address of the activity.
    function getActivityApprovers(string memory _activity) 
        public 
        view 
        returns(address[] memory)
    {
        return activityData[_activity].approvers;
    }

    
    /// @dev Returns Owner address of the activity.
    /// @param _activity Activity name.
    /// @return Owner address of the activity.
    function getActivityOwner(string memory _activity) public view returns(address) {
        return activityData[_activity].activityOwner;
    }


    /// @dev Returns prority of activity.
    /// @param _activity Activity name.
    /// @return activity priority.
    function getActivityPriority(string memory _activity) public view returns(uint8) {
        return activityData[_activity].priority;
    }

    /// @dev Returns status of the activity.
    /// @param _phase Activity phase.
    /// @param _priority Activity priority.
    /// @return status of activity.
    function getActivityStatus(uint8 _phase, uint8 _priority,uint _transID) 
        public 
        view 
        returns(string memory) 
    {
        return activityExecutions[_phase][_priority][_transID].status;
    }


    /// @dev Returns approvers count of the activity.
    /// @param _phase Activity phase.
    /// @param _transId Activity transactionId.
    /// @param _activity Activity name.
    /// @return approvers count  of activity.
    function getActivityApproversCount(uint8 _phase,uint _transId,string memory _activity) 
        public 
        view 
        returns(uint8) 
    {
        return count;
    }


    /// @dev Returns approvers address of the activity.
    /// @param _phase Activity phase.
    /// @param _transId Activity transactionId.
    /// @param _activity Activity name.
    /// @return approvers address of activity.
    function getActivityApproversAddress(uint8 _phase,uint _transId,string memory _activity) 
        public 
        payable 
        returns(address [] memory) 
    {
        address [] memory approversList;
        if((approversStatus[_phase][_activity][_transId][approversList[i]]).compareToIgnoreCase("accept"))
            {
                approversAddress.push(approversList[i]);
            }
        }

        return approversAddress;
    }
    /// @dev Returns approver status of the activity.
    /// @param _phase Activity phase.
    /// @param _activity Activity name.
    /// @param _activity Activity approver address.
    /// @return approver status of activity.
    function getApproverStatus(uint8 _phase, string memory _activity, address _approver,uint _transID)     public 
        view 
        returns(string memory) 
    {
        return approversStatus[_phase][_activity][_transID][_approver];
    }
    
    // @dev Returns Residual Tokens from transID.
    // @param transID transactionID of the activity.
    // @dev Returns file hash and password.
    // @param _phase Phase of the activity.
    // @param _activity Activity name.
    // @param _fileName Name of the file.
    // @return array of the file hash and password.
    function getFileHash(
        uint8 _phase, 
        string memory _activity, 
        string memory _fileName
    ) 
        public view returns (string memory) {
        return files[_phase][_activity][_fileName];
    }


      function customerTransfer( address _from, address _to, uint256 _value , uint startToken , uint endToken) public returns (bool success) {
       if (balances[_from] >= value && value > 0)
       {
        balances[_from] -= _value;
        balances[_to] += _value;
        emit CustomerTransfer(_from, _to, value, now,startToken,endToken);
        return true;
       }
       else
       {
           return false;
       }
    }
    

}

    contract ABCProduction is ABC {
    /// @dev Fallback function allows to deposit ether.
    function()
    external
    payable
    {
        if (msg.value > 0)
            emit Deposit(msg.sender, msg.value);
    }


    /*
    * Public functions
    */
    /// @dev Contract constructor sets tokens to owner address.
    /// @param _tokens Number of tokens.
    /// @param _miningPlan Symbol of token.

    constructor(
        address _budgetWallet,
        uint256 _tokens, 

    )
        public
    {
        balances[_budgetWallet] = _tokens*10**_decimal;    // creator gets all initial tokens
        totalSupply = _tokens*10**_decimal;             // total supply of token
     
    }


}

 

