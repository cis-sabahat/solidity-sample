pragma experimental ABIEncoderV2;

contract DocumentUpload{

    struct Document{
        address owner;
        string Hash;
        string status;
    }
    mapping(address => Document[])userDocumentList;

    function addDocument(address _addr, address _owner, string _hash, string _status) {
        userDocumentList[_addr].push(Document(_owner, _hash, _status));
    }

    function updateDocstatus(address _addr, string _hash, string _status) {
        Document[] storage doc = userDocumentList[_addr];
        doc[0].status = _status;
    }
    function getDocumentList(address _addr)  returns(Document[] userDocList){
        Document[]  docList = userDocumentList[_addr];
        return (docList);
    }

    function getDocument(address _addr, uint _docposition)  returns(string userDoc){
        Document[] memory userDocList = getDocumentList(_addr);
        string memory  DocHash = userDocList[_docposition].Hash;
        address DocOwner = (userDocList[_docposition].owner); //
        string memory Docstatus = (userDocList[_docposition].status);
        return (append(Docstatus, DocHash));


    }
    function append(string a, string b) internal pure returns(string) {
        return string(abi.encodePacked(a, b));

    }

}
