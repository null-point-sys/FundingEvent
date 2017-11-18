pragma solidity ^0.4.18;

contract FundingEvent {
    
    function FundingEvent() public {
            
    }
    
    Speaker[] public _speakers;
    mapping(address => Participant) public participants;
    Location[] private _locations;
    Meetup[] private _meetups;
    mapping(address => mapping(address => uint)) donators;
    mapping(address => uint) meetupBalances;
    
    struct Speaker {
        address owner;
        string name;
        string bio;
        string url;
    }
    
    struct Participant {
        string name;
        string email;
    }
    
    struct Location {
        address owner;
        string streetAddress;
        uint cost;
        uint capacity;
    }
    
    enum MeetupStatus {
        ongoing, finished, cancelled
    }
    
    struct Meetup {
        address creator;
        string title;
        uint blockTime;
        address speaker;
        address location;
        uint minAmount;
        MeetupStatus status;
    }
    
    function registerSpeaker(string name, string bio, string url) public {
        require(!speakerExists(msg.sender));
        _speakers.push(Speaker(msg.sender, name, bio, url));
    }
    
    function getSpeakers() public view returns (Speaker[]) {
        return _speakers;  
    }
    
    function getSpeaker(uint index) public view returns (string, string, string) {
        Speaker speaker = _speakers[index];
        require(bytes(speaker.name).length != 0);
        return (speaker.name, speaker.bio, speaker.url);
    }

    function registerParticipant(string name, string email) public {
        participants[msg.sender] = Participant(name, email);
    }
    
    function registerLocation(string streetAddress, uint cost, uint capacity) public {
        _locations.push(Location(msg.sender, streetAddress, cost, capacity));
    }
    
    function getLocations() public view returns (Location[]) {
        return _locations;
    }
    
    function getLocation(uint index) public view returns (string, uint, uint) {
        Location location = _locations[index];
        require(location.capacity > 0);
        return (location.streetAddress, location.cost, location.capacity);
    }
    
    function createMeetup(string title, uint blockTime, address speaker, address location) public {
        require(locationExists(location));
        require(speakerExists(speaker));
        require(bytes(title).length > 0);
        require(blockTime > now);
        _meetups.push(Meetup(msg.sender, title, blockTime, speaker, location, 0, MeetupStatus.ongoing));
    }
    
    function getMeetups() public view returns (Meetup[]) {
        return _meetups;
    }
    
    function getMeetup(uint index) public view returns (address, string, uint, address, address, uint, uint) {
        Meetup meetup = _meetups[index];
        require(meetup.blockTime != 0);
        return (meetup.creator, meetup.title, meetup.blockTime, meetup.speaker, meetup.location, meetup.minAmount, uint(meetup.status));
    }
    
    function donate(address meetup) payable public meetupExists(meetup) {
        require(msg.value > 0);
        donators[meetup][msg.sender] += msg.value;
        meetupBalances[meetup] += msg.value;
    }
    
    function setMinMeetupAmount(address meetup, uint minAmount) public meetupExists(meetup) {
        //TODO Should be storage because we change the state below, but we get error if using storage
        //Meetup storage currentMeetup = getMeetup(meetup);
        require(speakerExists(msg.sender));
        require(getMeetup(meetup).speaker == msg.sender);
        require(msg.value > 0);
        getMeetup(meetup).minAmount = minAmount;
    }
    
    function participantWithdrawal(address meetup) public meetupExists(meetup) participantExists(msg.sender) {
        uint amount = donators[meetup][msg.sender];
        require(amount > 0);
        if (getMeetup(meetup).status != MeetupStatus.finished) {
            donators[meetup][msg.sender] = 0;
            msg.sender.transfer(amount);
        }
    }
    
    function speakerWithdrawal(address meetup) public meetupExists(meetup) {
        require(speakerExists(msg.sender));
        //TODO Should be storage because we change the state below, but we get error if using storage
        Meetup memory currentMeetup = getMeetup(meetup);
        require(currentMeetup.blockTime < now);
        uint amount = meetupBalances[meetup];
        meetupBalances[meetup] = 0;
        
        if (currentMeetup.status != MeetupStatus.finished) {
            msg.sender.transfer(amount);
            getMeetup(meetup).status = MeetupStatus.finished;
        }
    }
    
    function getMeetup(address meetup) private constant returns (Meetup) {
        for (uint i=0; i < _meetups.length; i++) {
            if (_meetups[i].creator == meetup) {
                return _meetups[i];
            }
        }
        revert();
    }
    
    function speakerExists(address speaker) private returns (bool) {
        for (uint i=0; i < _speakers.length; i++) {
            if (_speakers[i].owner == speaker) {
                return true;
            }
        }
        return false;
    }
    
    modifier participantExists(address participant) {
        require(bytes(participants[participant].name).length != 0);
        _;
    }
    
    function locationExists(address location) private returns (bool) {
        for (uint i=0; i < _locations.length; i++) {
            if (_locations[i].owner == location) {
                return true;
            }
        }
        return false;
    }
    
    modifier meetupExists(address meetup) {
        bool success = false;
        for (uint i=0; i < _meetups.length; i++) {
            if (_meetups[i].creator == meetup) {
                success = true;
                break;
            }
        }
        if (success == false) {
            revert();
        }
        _;
    }
}