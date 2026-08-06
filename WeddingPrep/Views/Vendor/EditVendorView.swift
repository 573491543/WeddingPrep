import SwiftUI
import SwiftData

struct EditVendorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var vendor: Vendor?

    @State private var name = ""
    @State private var serviceType = VendorServiceType.dress
    @State private var priceText = ""
    @State private var price: Double = 0
    @State private var status = VendorStatus.intentional
    @State private var hasContactDate = false
    @State private var contactDate = Date()
    @State private var phone = ""
    @State private var notes = ""

    private var isEditing: Bool { vendor != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("商家信息") {
                    TextField("商家名称", text: $name)
                    Picker("服务类型", selection: $serviceType) {
                        ForEach(VendorServiceType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    HStack {
                        Text("报价")
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
                }

                Section("状态") {
                    Picker("合作状态", selection: $status) {
                        ForEach(VendorStatus.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                }

                Section("联系信息") {
                    Toggle("记录联系日期", isOn: $hasContactDate)
                    if hasContactDate {
                        DatePicker("联系日期", selection: $contactDate, displayedComponents: .date)
                            .environment(\.locale, Locale(identifier: "zh_CN"))
                    }
                    TextField("联系电话", text: $phone)
                        .keyboardType(.phonePad)
                }

                Section("备注") {
                    TextField("备注...", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section {
                    Button(isEditing ? "保存修改" : "添加商家") {
                        saveVendor()
                    }
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.primaryColor)
                    .frame(maxWidth: .infinity)
                    .disabled(name.isEmpty)

                    if isEditing {
                        Button("删除商家", role: .destructive) {
                            deleteVendor()
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(isEditing ? "编辑商家" : "新增商家")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .onAppear {
                loadVendor()
            }
        }
    }

    private func loadVendor() {
        guard let vendor else { return }
        name = vendor.name
        serviceType = VendorServiceType(rawValue: vendor.serviceType) ?? .dress
        price = vendor.price
        priceText = String(format: "%.0f", vendor.price)
        status = VendorStatus(rawValue: vendor.status) ?? .intentional
        hasContactDate = vendor.contactDate != nil
        contactDate = vendor.contactDate ?? Date()
        phone = vendor.phone
        notes = vendor.notes
    }

    private func saveVendor() {
        if let vendor {
            vendor.name = name
            vendor.serviceType = serviceType.rawValue
            vendor.price = price
            vendor.status = status.rawValue
            vendor.contactDate = hasContactDate ? contactDate : nil
            vendor.phone = phone
            vendor.notes = notes
            vendor.updatedAt = Date()
        } else {
            let newVendor = Vendor(
                name: name,
                serviceType: serviceType.rawValue,
                price: price,
                status: status.rawValue,
                contactDate: hasContactDate ? contactDate : nil,
                phone: phone,
                notes: notes
            )
            modelContext.insert(newVendor)
        }
        try? modelContext.save()
        dismiss()
    }

    private func deleteVendor() {
        guard let vendor else { return }
        modelContext.delete(vendor)
        try? modelContext.save()
        dismiss()
    }
}
