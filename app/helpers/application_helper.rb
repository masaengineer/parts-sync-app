module ApplicationHelper
  include ActionView::Helpers::AssetUrlHelper

  def full_title(page_title = "")
    base_title = "Parts Sync"
    page_title.empty? ? base_title : "#{page_title} | #{base_title}"
  end

  def default_meta_tags
    {
      site: "Parts Sync",
      title: "カーパーツ売上管理システム",
      reverse: true,
      charset: "utf-8",
      description: "カーパーツ売上管理システムで、効率的な在庫管理と売上分析を実現",
      keywords: "カーパーツ,売上管理,システム",
      canonical: request.original_url,
      separator: "|",
      icon: [
        { href: image_url("logo/favicon.svg"), sizes: "60x60" },
        { href: image_url("logo/favicon.png"), rel: "icon", sizes: "90x90", type: "image/png" }
      ],
      og: {
        site_name: "Parts Sync",
        title: "カーパーツ売上管理システム",
        description: "カーパーツ売上管理システムで、効率的な在庫管理と売上分析を実現",
        type: "website",
        url: request.original_url,
        image: image_url("ogp.png"),
        locale: "ja_JP"
      },
      twitter: {
        card: "summary_large_image",
        site: "@",
        creator: "@",
        image: image_url("ogp.png")
      }
    }
  end
end
