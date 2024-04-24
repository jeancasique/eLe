
import Foundation
//import FirebaseFirestore
/*
class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    
    func saveTransaction(transaction: Transaction, completion: @escaping (Bool) -> Void) {
        db.collection("transactions").document(transaction.id).setData([
            "email": transaction.email,
            "amount": transaction.amount,
            "date": Timestamp(date: transaction.date)
        ]) { error in
            if let error = error {
                print("Error writing document: \(error)")
                completion(false)
            } else {
                print("Document successfully written!")
                completion(true)
            }
        }
    }

    func fetchTransactions(completion: @escaping ([Transaction]?, Error?) -> Void) {
        db.collection("transactions").getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                completion(nil, err)
            } else {
                var transactions = [Transaction]()
                for document in querySnapshot!.documents {
                    let data = document.data()
                    let transaction = Transaction(
                        id: document.documentID,
                        email: data["email"] as? String ?? "",
                        amount: data["amount"] as? Double ?? 0.0,
                        date: (data["date"] as? Timestamp)?.dateValue() ?? Date()
                    )
                    transactions.append(transaction)
                }
                completion(transactions, nil)
            }
        }
    }
}
 /**/*/
