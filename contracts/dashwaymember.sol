// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

contract DashwayMember {
    struct Member {
        string firstname;
        string lastname;
        bytes32 phone;
        uint256 createDate;
        bool isActive;        
        address memberAddr;
    }

    enum EditorRole {
        READER,
        WRITER        
    }

    struct Editor {
        address editorAddress;
        string name;
        EditorRole role;
        uint256 createDate;
    }

    // Mapping
    mapping(address => Member) private members; // Key address
    mapping(bytes32 => address) private addressMembers; // Key firstname + ' ' + lastname
    mapping(address => Editor) private editors; // Key address

    // State variable stored permanently in smart contract storage
    address private owner;
    address[] private storedMembersAddress;
    address[] private storedEditorsAddress;
    
    // Event
    event NewMember(string firstname, string lastname, address memberAddr);

    // Constructor
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
    }

    // Save Member
    function saveMember(Member memory newMember) public isWriter payable {        
        // Search Member
        Member memory oldMember = members[newMember.memberAddr];

        // Update
        if(abi.encodePacked(oldMember.firstname).length > 0){
            members[newMember.memberAddr].firstname = newMember.firstname;
            members[newMember.memberAddr].lastname = newMember.lastname;
            members[newMember.memberAddr].phone = newMember.phone;
            members[newMember.memberAddr].isActive = newMember.isActive;
        }
        // Create
        else {
            address newAddress = generateRandomAddress();
            members[newAddress].memberAddr = newAddress;
            members[newAddress].firstname = newMember.firstname;
            members[newAddress].lastname = newMember.lastname;
            members[newAddress].phone = newMember.phone;
            members[newAddress].createDate = newMember.createDate;
            members[newAddress].isActive = newMember.isActive;
            // Maping address
            bytes32 nameHash = keccak256(abi.encodePacked(newMember.firstname, " ", newMember.lastname));
            addressMembers[nameHash] = newAddress;
            // Save addres in State data
            storedMembersAddress.push(newAddress);
            // Alert
            emit NewMember(newMember.firstname, newMember.lastname, newAddress);
        }
    }

    // Delete member
    function deleteMember(address memberAddress) public isWriter payable {
        Member storage memberToDelete = members[memberAddress];
        require(memberToDelete.memberAddr == memberAddress, "Member not found");

        // Remove from the members mapping
        delete members[memberAddress];

        // Remove from the addressMembers mapping'
        bytes32 nameHash = keccak256(abi.encodePacked(memberToDelete.firstname, " ", memberToDelete.lastname));
        delete addressMembers[nameHash];

        // Remove from the storedMembersAddress array
        uint256 indexToDelete;
        bool found;
        for (uint256 i = 0; i < storedMembersAddress.length; i++) {
            if (storedMembersAddress[i] == memberAddress) {
                indexToDelete = i;
                found = true;
                break;
            }
        }
        
        require(found, "Member not found in storedMembersAddress array");
        // Shift elements of array
        for (uint256 i = indexToDelete; i < storedMembersAddress.length - 1; i++) {
            storedMembersAddress[i] = storedMembersAddress[i+1];
        }
        storedMembersAddress.pop();
    }

    // Get Member by Address
    function getMemberByAddress(address memberAddress) public isReader view returns (Member memory) {
        return members[memberAddress];
    }

    // Get Member by Fullname
    function getMemberByFullname(string memory fullName) public isReader view returns (Member memory) {
        bytes32 nameHash = keccak256(abi.encodePacked(fullName));
        address memberAddress = addressMembers[nameHash];
        require(memberAddress != address(0), "Member not found");
        return members[memberAddress];
    }

    // Get All member
    function getAllMembers() public isReader view returns (Member[] memory) {     
        Member[] memory result = new Member[](storedMembersAddress.length);
        for (uint256 i = 0; i < storedMembersAddress.length; i++) {
            result[i] = getMemberByAddress(storedMembersAddress[i]);
        }
        return result;
    }

    // Random address hasKey
    function generateRandomAddress() private view returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(block.timestamp, msg.sender, blockhash(block.number - 1)));
        return address(uint160(uint256(hash)));
    }

    // Security
    modifier isOwner(){
        require(msg.sender == owner, "You don't have authorize");
       _; // continue executing rest of method body
    }

    modifier isReader(){
        require(editors[msg.sender].editorAddress != address(0), "Role not found");

        require(editors[msg.sender].role == EditorRole.READER || editors[msg.sender].role == EditorRole.WRITER, "Role invalid");
        _;
    }

    modifier isWriter(){
        require(editors[msg.sender].editorAddress != address(0), "Role not found");

        require(editors[msg.sender].role == EditorRole.WRITER, "Role invalid");
        _;
    }

    function saveEditor(Editor memory newEditor) public isOwner payable {
        // Search Editor
        Editor memory oldEditor = editors[newEditor.editorAddress];

        // Update
        if(abi.encodePacked(oldEditor.name).length > 0){
            editors[newEditor.editorAddress].role =  newEditor.role;
        }
        else{
            // Save data in Mapping Data
            address newAddress = newEditor.editorAddress;
            editors[newAddress].editorAddress = newAddress;
            editors[newAddress].name = newEditor.name;
            editors[newAddress].role = newEditor.role;
            editors[newAddress].createDate = newEditor.createDate;
            // Save address in State data
            storedEditorsAddress.push(newAddress);
        }
    }

    function getAllEditors() public isOwner view returns (Editor[] memory) {     
        uint256 length = storedEditorsAddress.length;
        Editor[] memory result = new Editor[](length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = editors[storedEditorsAddress[i]];
        }
        return result;
    }

    function deleteEditor(address editorAddress) public isOwner payable {
        Editor storage editorToDelete = editors[editorAddress];
        require(editorToDelete.editorAddress == editorAddress, "Editor not found");

        // Remove from the editors mapping
        delete editors[editorAddress];

        // Remove from the storedMembersAddress array
        uint256 indexToDelete;
        bool found;
        for (uint256 i = 0; i < storedEditorsAddress.length; i++) {
            if (storedEditorsAddress[i] == editorAddress) {
                indexToDelete = i;
                found = true;
                break;
            }
        }

        require(found, "Editor not found in storedEditorsAddress array");
        // Shift elements of array
        for (uint256 i = indexToDelete; i < storedEditorsAddress.length - 1; i++) {
            storedEditorsAddress[i] = storedEditorsAddress[i+1];
        }
        storedEditorsAddress.pop();
        
    }
    
}
