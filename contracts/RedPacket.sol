// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract RedPacket {
    // 红包结构体
    struct Packet {
        address sender;           // 发红包的人
        uint256 totalAmount;     // 红包总金额
        uint256 remainingAmount; // 剩余金额
        uint256 totalCount;      // 红包总个数
        uint256 remainingCount;  // 剩余个数
        bool isActive;           // 是否激活
        mapping(address => bool) claimed; // 记录已领取的地址
    }
    
    // 合约状态
    mapping(uint256 => Packet) public redPackets;
    uint256 public nextPacketId;
    
    // 事件记录
    event PacketCreated(
        uint256 indexed packetId,
        address indexed sender,
        uint256 totalAmount,
        uint256 totalCount
    );
    
    event PacketClaimed(
        uint256 indexed packetId,
        address indexed claimer,
        uint256 amount
    );
    
    event PacketRefunded(
        uint256 indexed packetId,
        address indexed sender,
        uint256 refundAmount
    );
    
    // 错误定义
    error InsufficientAmount();
    error InvalidCount();
    error PacketNotExists();
    error PacketNotActive();
    error AlreadyClaimed();
    error NoRemainingPackets();
    error OnlySenderCanRefund();
    error RefundFailed();
    
    // 创建红包
    function createRedPacket(uint256 _count) external payable {
        if (msg.value == 0) revert InsufficientAmount();
        if (_count == 0) revert InvalidCount();
        
        uint256 packetId = nextPacketId++;
        Packet storage packet = redPackets[packetId];
        
        packet.sender = msg.sender;
        packet.totalAmount = msg.value;
        packet.remainingAmount = msg.value;
        packet.totalCount = _count;
        packet.remainingCount = _count;
        packet.isActive = true;
        
        emit PacketCreated(packetId, msg.sender, msg.value, _count);
    }
    
    // 抢红包
    function claimRedPacket(uint256 _packetId) external {
        Packet storage packet = redPackets[_packetId];
        
        if (packet.sender == address(0)) revert PacketNotExists();
        if (!packet.isActive) revert PacketNotActive();
        if (packet.claimed[msg.sender]) revert AlreadyClaimed();
        if (packet.remainingCount == 0) revert NoRemainingPackets();
        
        // 计算这次能领到的金额（简单平均分配）
        uint256 claimAmount;
        if (packet.remainingCount == 1) {
            // 最后一个红包，领取所有剩余金额
            claimAmount = packet.remainingAmount;
        } else {
            // 随机分配（简单实现：在剩余平均值的50%-150%之间）
            uint256 avgAmount = packet.remainingAmount / packet.remainingCount;
            uint256 randomFactor = (uint256(keccak256(abi.encodePacked(
                block.timestamp, 
                block.difficulty, 
                msg.sender,
                _packetId
            ))) % 101) + 50; // 50-150
            claimAmount = (avgAmount * randomFactor) / 100;
            
            // 确保不超过剩余金额
            if (claimAmount > packet.remainingAmount) {
                claimAmount = packet.remainingAmount;
            }
        }
        
        // 更新状态
        packet.claimed[msg.sender] = true;
        packet.remainingAmount -= claimAmount;
        packet.remainingCount--;
        
        // 如果红包领完了，设置为非激活状态
        if (packet.remainingCount == 0) {
            packet.isActive = false;
        }
        
        // 转账
        (bool success, ) = payable(msg.sender).call{value: claimAmount}("");
        require(success, "Transfer failed");
        
        emit PacketClaimed(_packetId, msg.sender, claimAmount);
    }
    
    // 退款（只有发红包的人可以调用，且红包还有剩余）
    function refundRedPacket(uint256 _packetId) external {
        Packet storage packet = redPackets[_packetId];
        
        if (packet.sender != msg.sender) revert OnlySenderCanRefund();
        if (!packet.isActive) revert PacketNotActive();
        
        uint256 refundAmount = packet.remainingAmount;
        packet.remainingAmount = 0;
        packet.remainingCount = 0;
        packet.isActive = false;
        
        (bool success, ) = payable(msg.sender).call{value: refundAmount}("");
        if (!success) revert RefundFailed();
        
        emit PacketRefunded(_packetId, msg.sender, refundAmount);
    }
    
    // 查看红包信息
    function getPacketInfo(uint256 _packetId) external view returns (
        address sender,
        uint256 totalAmount,
        uint256 remainingAmount,
        uint256 totalCount,
        uint256 remainingCount,
        bool isActive
    ) {
        Packet storage packet = redPackets[_packetId];
        return (
            packet.sender,
            packet.totalAmount,
            packet.remainingAmount,
            packet.totalCount,
            packet.remainingCount,
            packet.isActive
        );
    }
    
    // 检查地址是否已经领取过红包
    function hasClaimed(uint256 _packetId, address _user) external view returns (bool) {
        return redPackets[_packetId].claimed[_user];
    }
    
    // 获取当前红包ID
    function getCurrentPacketId() external view returns (uint256) {
        return nextPacketId;
    }
}