// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@forge-std/Test.sol";
import "../src/Voting.sol";
import {UltraVerifier as MembershipVerifier} from "../circuits/membership/contract/plonk_vk.sol";
import {UltraVerifier as VotingVerifier} from "../circuits/verifyVoteCommit/contract/plonk_vk.sol";

contract VotingTest is Test {
    Voting public voteContract;
    MembershipVerifier memberVerifier;
    VotingVerifier votingVerifier;

    bytes membershipProofBytes;
    bytes voteProofBytes;

    bytes32 merkleRoot = 0x20c77d6d51119d86868b3a37a64cd4510abd7bdb7f62a9e78e51fe8ca615a194;
    //FIX ME
    bytes32 membershipNullifierHash = 0x0bf0dd2fad1a8da018371f0a8dac56016d270d2e178a847a3ac724d033d1d858;
    bytes32 votingNullifierHash = 0x12b3d9b0dd5322011afa765a8bcde14a31132c68e9358cda7145461f92985ea2;

    bytes32 voteCommitment = 0x26f0d3376bdd2a375769ac4a26848b306a595393dcd5ef9f2d40d522b0c1bd77;
    function setUp() public {
        memberVerifier = new MembershipVerifier();
        votingVerifier = new VotingVerifier();

        voteContract = new Voting(merkleRoot, address(memberVerifier), address(votingVerifier));

        voteContract.createProposal(uint32(block.timestamp + 50000), uint32(block.timestamp + 100000));
        
        // Membership proof
        string memory membershipProof = vm.readLine("./circuits/membership/proofs/p.proof");
        emit log_string(membershipProof);
        membershipProofBytes = vm.parseBytes(membershipProof);
        // VoteCommitment proof
        string memory voteProof = vm.readLine("./circuits/verifyVoteCommit/proofs/p.proof");
        voteProofBytes = vm.parseBytes(voteProof); 
    }

    function testCommitVote() public {
        voteContract.commitVote(membershipProofBytes, 0, membershipNullifierHash, voteCommitment);
    }

    function testRevealVote() public {
        voteContract.commitVote(membershipProofBytes, 0, membershipNullifierHash, voteCommitment);
        vm.warp(block.timestamp + 50001);
        voteContract.revealVote(voteProofBytes, 0, votingNullifierHash, voteCommitment, 1);
    }

    function testFail_CommitVoteOutofRange() public {
       vm.warp(block.timestamp + 50001);
       voteContract.commitVote(membershipProofBytes, 0, membershipNullifierHash, voteCommitment); 
    }

    function testFail_RevealVoteOutofRange() public {
       voteContract.commitVote(membershipProofBytes, 0, membershipNullifierHash, voteCommitment);
       vm.warp(block.timestamp + 100001);
       voteContract.revealVote(voteProofBytes, 0, votingNullifierHash, voteCommitment, 1); 
    }

    function testFail_CommitDoubleCount() public {
      voteContract.commitVote(membershipProofBytes, 0, membershipNullifierHash, voteCommitment);
      vm.warp(block.timestamp + 1000);
      voteContract.commitVote(membershipProofBytes, 0, membershipNullifierHash, voteCommitment); 
    }

    function testFail_RevealDoubleCount() public {
       voteContract.commitVote(membershipProofBytes, 0, membershipNullifierHash, voteCommitment);
       vm.warp(block.timestamp + 50001);
       voteContract.revealVote(voteProofBytes, 0, votingNullifierHash, voteCommitment, 1); 
       vm.warp(block.timestamp + 60000);
       voteContract.revealVote(voteProofBytes, 0, votingNullifierHash, voteCommitment, 1); 
    }

    function testFail_CommitVoteWrongNullifier() public {
      bytes32 wrongNullifier = 0x1bf0dd2fad1a8da018371f0a8dac56016d270d2e178a847a3ac724d033d1d858; 
      voteContract.commitVote(membershipProofBytes, 0, wrongNullifier, voteCommitment);
    }

    function testFail_RevealVoteWrongNullifier() public {
       voteContract.commitVote(membershipProofBytes, 0, membershipNullifierHash, voteCommitment);
       vm.warp(block.timestamp + 50001); 
       bytes32 wrongNullifier = 0x1bf0dd2fad1a8da018371f0a8dac56016d270d2e178a847a3ac724d033d1d858; 
       voteContract.revealVote(voteProofBytes, 0, wrongNullifier, voteCommitment, 1);  
    }
}   