use dep::std;

fn main(root : pub Field, index : Field, secret: Field, priv_key: Field, proposalId: pub Field, hash_path : [Field; 2], voteCommit: pub Field, vote: Field) -> pub [Field; 2] {
    let note_commitment = std::hash::pedersen([priv_key, secret]);
    let nullifier = std::hash::pedersen([priv_key, proposalId, voteCommit]);
    assert(root == std::merkle::compute_merkle_root(note_commitment[0], index, hash_path));
    assert(vote as u8 <= 1);
    assert(voteCommit == std::hash::pedersen([priv_key, proposalId, vote])[0]);
    
    if (vote ==  1) {
        [nullifier[0], 1]
    } else {
        [nullifier[0], 0]
    }
    
}

#[test]
fn test_main() {
   
    
    let secret = 9;
    let commitment_0 =  std::hash::pedersen([0, secret])[0];
    let commitment_1 =  std::hash::pedersen([1, secret])[0];
    let commitment_2 =  std::hash::pedersen([2, secret])[0];
    let commitment_3 =  std::hash::pedersen([3, secret])[0];

    let left_branch = std::hash::pedersen([commitment_0, commitment_1])[0];
    let right_branch = std::hash::pedersen([commitment_2, commitment_3])[0];

    let root = std::hash::pedersen([left_branch, right_branch])[0];

    std::println("Merkle Tree:");
    std::println([root]);
    std::println([left_branch, right_branch]);
    std::println([commitment_0, commitment_1, commitment_2, commitment_3]);

    // priv_key, proposalID, voteå
    let voteCommit = std::hash::pedersen([0, 0, 1])[0];
    let hash_path = [commitment_1, right_branch];
    // (Root, Index, Secret, priv_key, proposal_id, hash_path, voteComit, vote)
    main(root, 0, 9, 0, 0,hash_path, voteCommit, 1);
}
