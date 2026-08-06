import SwiftUI
import SwiftData

struct EditMaterialView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var material: MaterialItem?
    var listType: MaterialListType = .purchase

    @State private var name = ""
    @State private var priceText = ""
    @State private var price: Double = 0
    @State private var quantity = 1
    @State private var category = MaterialCategory.other
    @State private var channel = MaterialChannel.taobao
    @State private var status = MaterialStatus.notPurchased
    @State private var notes = ""
    @State private var selectedListType: MaterialListType = .purchase

    private var isEditing: Bool { material != nil }

    private var totalPrice: Double {
        price * Double(quantity)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("物资信息") {
                    TextField("物品名称", text: $name)
                    HStack {
                        Text("单价")
                        Spacer()
                        TextField("0", text: $priceText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: priceText) { _, newValue in
                                let filtered = newValue.filter { $0.isNumber || $0 == "." }
                                priceText = filtered
                                price = Double(filtered) ?? 0
                            }
                        Text("元")
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    Stepper("数量 \(quantity)", value: $quantity, in: 1...999)
                }

                Section("分类") {
                    Picker("物资分类", selection: $category) {
                        ForEach(MaterialCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    Picker("采购渠道", selection: $channel) {
                        ForEach(MaterialChannel.allCases, id: \.self) { ch in
                            Text(ch.rawValue).tag(ch)
                        }
                    }
                }

                Section("采购状态") {
                    Picker("状态", selection: $status) {
                        ForEach(MaterialStatus.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    Picker("清单类型", selection: $selectedListType) {
                        ForEach(MaterialListType.allCases, id: \.self) { lt in
                            Text(lt.rawValue).tag(lt)
                        }
                    }
                }

                Section {
                    HStack {
                        Text("总价")
                        Spacer()
                        Text(DateHelper.formatCurrency(totalPrice))
                            .font(AppTheme.title)
                            .foregroundColor(AppTheme.accentColor)
                    }
                }

                Section("备注") {
                    TextField("备注...", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section {
                    Button(isEditing ? "保存修改" : "添加物资") {
                        saveMaterial()
                    }
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.primaryColor)
                    .frame(maxWidth: .infinity)
                    .disabled(name.isEmpty)

                    if isEditing {
                        Button("删除物资", role: .destructive) {
                            deleteMaterial()
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(isEditing ? "编辑物资" : "新增物资")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .onAppear {
                loadMaterial()
            }
        }
    }

    private func loadMaterial() {
        guard let material else {
            selectedListType = listType
            return
        }
        name = material.name
        price = material.price
        priceText = String(format: "%.0f", material.price)
        quantity = material.quantity
        category = MaterialCategory(rawValue: material.category) ?? .other
        channel = MaterialChannel(rawValue: material.channel) ?? .taobao
        status = MaterialStatus(rawValue: material.status) ?? .notPurchased
        notes = material.notes
        selectedListType = MaterialListType(rawValue: material.listType) ?? listType
    }

    private func saveMaterial() {
        if let material {
            material.name = name
            material.price = price
            material.quantity = quantity
            material.category = category.rawValue
            material.channel = channel.rawValue
            material.status = status.rawValue
            material.notes = notes
            material.listType = selectedListType.rawValue
            material.updatedAt = Date()
        } else {
            let newMaterial = MaterialItem(
                name: name,
                price: price,
                quantity: quantity,
                category: category.rawValue,
                channel: channel.rawValue,
                status: status.rawValue,
                notes: notes,
                listType: selectedListType.rawValue
            )
            modelContext.insert(newMaterial)
        }
        try? modelContext.save()
        dismiss()
    }

    private func deleteMaterial() {
        guard let material else { return }
        modelContext.delete(material)
        try? modelContext.save()
        dismiss()
    }
}
