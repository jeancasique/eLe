
//import FirebaseFirestore

class FirestoreManager {
    static let shared = FirestoreManager()
    private let db = Firestore.firestore()
    
    func saveTransaction(transaction: Transaction, completion: @escaping (Bool) -> Void) {
        db.collection("transactions").addDocument(data: [
            "email": transaction.email,
            "amount": transaction.amount,
            "date": transaction.date
        ]) { error in
            if let error = error {
                print("Error saving transaction: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Transaction successfully saved.")
                completion(true)
            }
        }
    }
}
