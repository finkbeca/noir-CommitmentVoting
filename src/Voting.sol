// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@solmate/auth/Owned.sol";
import {UltraVerifier as MembershipVerifier} from "../circuits/membership/contract/plonk_vk.sol";
import {UltraVerifier as VotingVerifier} from "../circuits/verifyVoteCommit/contract/plonk_vk.sol";

contract Voting is Owned {
    /*//////////////////////////////////////////////////////////////
                                DATASTRUCTURES
    //////////////////////////////////////////////////////////////*/

    MembershipVerifier membershipVerifier;
    VotingVerifier voteVerifier;

    bytes32 merkleRoot;

    struct Proposal {
        uint256 proposalEndTime;
        uint256 revealEndTime;
        uint32 yesVotes;
        uint32 noVotes;
    }
    uint32 proposalId;
    mapping(uint32 => Proposal) public Proposals;
    mapping(bytes32 => bool) nullifier;
    mapping(bytes32 => bool) committedVotes;

    /*//////////////////////////////////////////////////////////////
                                 ERRORs
    //////////////////////////////////////////////////////////////*/

    error InvalidVotingPeriod();
    error ProofAlreadySubmitted();
    error InvalidProof();

     /*//////////////////////////////////////////////////////////////
                                 FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    constructor(bytes32 _merkleroot, address membershipVerifierAddress, address voteVerifierAddress) Owned(msg.sender) {
        merkleRoot = _merkleroot;
        membershipVerifier = MembershipVerifier(membershipVerifierAddress);
        voteVerifier = VotingVerifier(voteVerifierAddress);
    }

    function createProposal(uint32 proposalEndTime, uint32 revealEndTime) external onlyOwner() returns (uint32) {
        if (revealEndTime <= proposalEndTime) {
            revert InvalidVotingPeriod();
        } 

        Proposals[proposalId] = Proposal(proposalEndTime,revealEndTime, 0, 0);
        proposalId++;
    }

    function commitVote(bytes calldata proof, uint32 Id, bytes32 nullifierHash, bytes32 commitedVote) external  {
        Proposal storage proposal = Proposals[Id];
        if (block.timestamp > proposal.proposalEndTime || proposal.proposalEndTime == 0 ) {
            revert InvalidVotingPeriod();
        }
        if (nullifier[nullifierHash] == true) {
            revert ProofAlreadySubmitted();
        }
        
        bytes32[] memory publicInputs = new bytes32[](3);
        publicInputs[0] = merkleRoot;
        publicInputs[1] = bytes32(uint(Id));
        publicInputs[2] = nullifierHash;

        bool result = membershipVerifier.verify(proof, publicInputs);
        if (result != true) {
            revert InvalidProof();
        }

        nullifier[nullifierHash] = true;
        committedVotes[commitedVote] = true;
        
    }

    function revealVote(bytes calldata proof, uint32 Id, bytes32 nullifierHash, bytes32 commitedVote, uint8 vote) external returns(bool) {
        
        Proposal storage proposal = Proposals[Id];
        if (block.timestamp <= proposal.proposalEndTime || block.timestamp > proposal.revealEndTime) {
            revert InvalidVotingPeriod();
        }
        /// @dev NOT the same nullifierHash as commiting a vote
        if (nullifier[nullifierHash] == true) {
            revert ProofAlreadySubmitted();
        }

        bytes32[] memory publicInputs = new bytes32[](5);
        publicInputs[0] = merkleRoot;
        publicInputs[1] = bytes32(uint(Id));
        publicInputs[2] = commitedVote;
        publicInputs[3] = bytes32(uint(vote));
        publicInputs[4] = nullifierHash;

        bool result = voteVerifier.verify(proof, publicInputs);
        if (result != true) {
            revert InvalidProof();
        }
        nullifier[nullifierHash] = true;

        if (vote == 0) {
            proposal.noVotes += 1;
        } else if (vote == 1) {
            proposal.yesVotes +=1;
        }
        return true;
    }
}
