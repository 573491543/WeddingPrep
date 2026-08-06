import SwiftUI
import SwiftData

struct VendorView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var vendors: [Vendor]

    @State private var searchText = ""
    @State private var selectedServiceIndex = 0
    @State private var selectedStatusIndex = 0
    @State private var showAddSheet = false
    @State private var editingVendor: Vendor?

    private var serviceTitles: [String] {
        ["全部"] + VendorServiceType.allCases.map { $0.rawValue }
    }

    private var statusTitles: [String] {
        ["全部"] + VendorStatus.allCases.map { $0.rawValue }
    }

    private var filteredVendors: [Vendor] {
        var filtered = vendors

        // Service type filter
        if selectedServiceIndex > 0 {
            let serviceType = VendorServiceType.allCases[selectedServiceIndex - 1]
            filtered = filtered.filter { $0.serviceType == serviceType.rawValue }
        }

        // Status filter
        if selectedStatusIndex > 0 {
            let status = VendorStatus.allCases[selectedStatusIndex - 1]
            filtered = filtered.filter { $0.status == status.rawValue }
        }

        // Search
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.serviceType.localizedCaseInsensitiveContains(searchText) ||
                $0.notes.localizedCaseInsensitiveContains(searchText)
            }
        }

        return filtered
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header stats
                headerStats

                // Search bar
                SearchBarView(text: $searchText, placeholder: "搜索商家名称、服务、备注")
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                // Service type filter
                FilterChipScrollView(titles: serviceTitles, selectedIndex: $selectedServiceIndex)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)

                // Status filter
                FilterChipScrollView(titles: statusTitles, selectedIndex: $selectedStatusIndex)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                // Vendor list
                if filteredVendors.isEmpty {
                    EmptyStateView(icon: "storefront", title: "暂无商家", subtitle: "点击右下角按钮添加商家")
                } else {
                    vendorListView
                }
            }
            .background(AppTheme.bg)
            .navigationTitle("商家资源")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .bottomTrailing) {
                FloatingActionButton {
                    showAddSheet = true
                }
                .padding(.trailing, 20)
                .padding(.bottom, 40)
            }
            .sheet(isPresented: $showAddSheet) {
                EditVendorView()
            }
            .sheet(item: $editingVendor) { vendor in
                EditVendorView(vendor: vendor)
            }
            .onReceive(NotificationCenter.default.publisher(for: .addVendor)) { _ in
                showAddSheet = true
            }
        }
    }

    // MARK: - Header Stats
    private var headerStats: some View {
        HStack(spacing: 16) {
            statBadge(count: vendors.filter { $0.status == VendorStatus.signed.rawValue }.count, label: "已签约", color: AppTheme.successColor)
            statBadge(count: vendors.filter { $0.status == VendorStatus.intentional.rawValue }.count, label: "意向中", color: AppTheme.warningColor)
            statBadge(count: vendors.filter { $0.status == VendorStatus.contacted.rawValue }.count, label: "已洽谈", color: AppTheme.infoColor)
            statBadge(count: vendors.filter { $0.status == VendorStatus.eliminated.rawValue }.count, label: "已淘汰", color: Color.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func statBadge(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(AppTheme.title)
                .foregroundColor(color)
            Text(label)
                .font(AppTheme.smallCaption)
                .foregroundColor(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                .fill(color.opacity(0.08))
        )
    }

    // MARK: - Vendor List
    private var vendorListView: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(filteredVendors, id: \.id) { vendor in
                    VendorCardView(vendor: vendor) {
                        editingVendor = vendor
                    }
                    .contextMenu {
                        Button {
                            editingVendor = vendor
                        } label: {
                            Label("编辑", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            deleteVendor(vendor)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
    }

    private func deleteVendor(_ vendor: Vendor) {
        modelContext.delete(vendor)
        try? modelContext.save()
    }
}
