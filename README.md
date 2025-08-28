我来为你创建一个简单的发红包智能合约，适用于 Sepolia 测试网。这是一个完整的红包智能合约，适用于 Sepolia 测试网。主要功能包括：

## 核心功能

1. **创建红包** (`createRedPacket`)
   - 发送 ETH 创建红包，指定红包个数
   - 记录创建事件

2. **抢红包** (`claimRedPacket`)
   - 用户抢红包，随机分配金额
   - 防止重复领取
   - 记录领取事件

3. **退款** (`refundRedPacket`)
   - 创建者可以退回未领完的红包
   - 记录退款事件

## 事件记录
所有操作都通过 emit 记录：
- `PacketCreated`: 记录红包创建
- `PacketClaimed`: 记录红包领取
- `PacketRefunded`: 记录红包退款

## 部署到 Sepolia 测试网

1. **获取测试 ETH**
   - 访问 [Sepolia Faucet](https://sepoliafaucet.com/) 获取测试币

2. **使用 Remix IDE 部署**
   ```
   1. 打开 https://remix.ethereum.org/
   2. 创建新文件，粘贴合约代码
   3. 编译合约（Solidity 0.8.19+）
   4. 在 Deploy 页面选择 "Injected Provider - MetaMask"
   5. 确保 MetaMask 连接到 Sepolia 网络
   6. 点击 Deploy
   ```

3. **使用示例**
   ```javascript
   // 创建红包（发送 0.1 ETH，分成 5 个红包）
   await contract.createRedPacket(5, {value: ethers.utils.parseEther("0.1")});
   
   // 抢红包
   await contract.claimRedPacket(0); // 抢 ID 为 0 的红包
   
   // 查看红包信息
   const info = await contract.getPacketInfo(0);
   ```

这个合约包含了完整的错误处理、事件记录和安全检查，可以直接部署到 Sepolia 测试网使用！