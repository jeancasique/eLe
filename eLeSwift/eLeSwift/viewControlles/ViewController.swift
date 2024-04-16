import UIKit

class ViewController: UIViewController {
    
    //Outlet
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var amountTextField: UITextField!
    //Actions
    @IBAction func donateButtonTapped(_ sender: UIButton) {}
     //Properties
        var transactions: [Transaction] = []
        
        override func viewDidLoad() {
            super.viewDidLoad()
            // Fetch transactions
            FirestoreService.shared.fetchTransactions { [weak self] transactions, error in
                if let transactions = transactions {
                    self?.transactions = transactions
                    DispatchQueue.main.async {
                        // Reload your UI here
                    }
                } else if let error = error {
                    print("Error fetching transactions: \(error)")
                }
            }
        }
        //metheds
        func saveTransaction() {
            let newTransaction = Transaction(id: UUID().uuidString, email: "example@example.com", amount: 99.99, date: Date())
            FirestoreService.shared.saveTransaction(transaction: newTransaction) { success in
                if success {
                    print("Transaction saved successfully")
                } else {
                    print("Error saving transaction")
                }
            }
            
        }
    }
