actor Main
    let sellerMoney:Purse
    let sellerGoods:Purse
    let buyerMoney:Purse
    let buyerGoods:Purse
    let env:Env
    new create(env': Env)=>
        env = env'
        env.out.print("---Constructing purses---")
        sellerMoney = Purse.create(env, "sellerMoney","GBP",0)
        sellerGoods= Purse.create(env, "sellerGoods","Book",1)
        buyerMoney = Purse.create(env, "buyerMoney","GBP",50)
        buyerGoods= Purse.create(env, "buyerGoods","Book",0)
        env.out.print("---Constructor completed---")
        env.out.print(".")
        env.out.print(".")
        env.out.print("---Dealing---")
        deal(10,"Book",1)
        env.out.print("---Deal completed---")
        env.out.print(".")
        env.out.print(".")
        sellerMoney.printbal()
        sellerGoods.printbal()
        buyerMoney.printbal()
        buyerGoods.printbal()
    fun ref deal(price:U32, good:String, amt: U32):Bool=>

        //sellerMoney trusts escrowMoney
        let escrowMoney:Purse = sellerMoney.sprout()
        var verifyMoney: Bool = false 
        //verify escrowMoney trusts sellerMoney
        verifyMoney = escrowMoney.deposit(0, sellerMoney)
            if verifyMoney is false then return false end
        //verify buyerMoney trusts escrowMoney
        verifyMoney = buyerMoney.deposit(0, escrowMoney)
            if verifyMoney is false then return false end
        //verify escrowMoney trusts buyerMoney
        verifyMoney = escrowMoney.deposit(0, buyerMoney)
            if verifyMoney is false then return false end

        //buyerGoods trusts escrowGoods 
        let escrowGoods:Purse = buyerGoods.sprout()
        var verifyGoods: Bool = false 
        //verify escrowGoods trusts buyerGoods
        verifyGoods = escrowGoods.deposit(0, buyerGoods)
            if verifyGoods is false then return false end
        //verify sellerGoods trusts escrowGoods
        verifyGoods = sellerGoods.deposit(0, escrowGoods)
            if verifyGoods is false then return false end
        //verify escrowGoods trusts sellerGoods
        verifyGoods = escrowGoods.deposit(0, sellerGoods)
            if verifyGoods is false then return false end

        env.out.print("---moneyTransfer to escrowMoney from BuyerMoney---")
        let moneyTransfer: Bool = escrowMoney.deposit(price,buyerMoney)
        if moneyTransfer is false then 
            env.out.print("insufficient money or different mint/currency") 
            return false end
        escrowMoney.printbal()
        buyerMoney.printbal()

        env.out.print("---goodsTransfer to escrowGoods from sellerGoods---")
        let goodsTransfer: Bool = escrowGoods.deposit(amt,sellerGoods)
        if goodsTransfer is false then  //we have to reverse the buyer transaction
            env.out.print("insufficient amt of goods") 
            buyerMoney.deposit(price, escrowMoney)
            return false end
        escrowGoods.printbal()
        sellerGoods.printbal()

        //if we reach here, we can complete the transaction
        env.out.print("---moneyTransfer to sellerMoney from escrowMoney---")
        sellerMoney.deposit(price, escrowMoney)

        env.out.print("---goodTransfer to buyerGoods from escrowGoods---")
        buyerGoods.deposit(amt, escrowGoods)
        true
        


class Purse 
    let env: Env
    let name: String val
    let resource_type: String val
    let _childPurses: Array[Purse] ref
    var _qty: U32

    new create(env': Env, name': String, resource_type': String val, qty':U32 = 0)=>
        env = env'
        name = name'
        resource_type = resource_type'
        _qty = qty'
        _childPurses = Array[Purse]
        printbal()
    fun ref sprout(): Purse =>
        let purse = Purse.create(env, "escrow_"+resource_type, resource_type)
        _childPurses.push(purse)
        purse
    fun ref zero() =>
        _qty = 0
        
    fun ref deposit(qty': U32, src': Purse):Bool val =>
        if (src'.withdraw(qty') is true) and (src'.resource_type is resource_type) then
            _qty = _qty + qty'
            return true
        end
        false

    fun ref withdraw(qty': U32):Bool val=>
        if (qty'<= _qty) then 
            _qty = _qty - qty'
            return true
        end 
        false

    fun printbal()=>
        env.out.print(name+": ("+resource_type+", "+_qty.string()+")")
