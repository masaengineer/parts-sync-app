namespace :test do
  desc "全てのテストを実行します"
  task :all => :environment do
    system "RAILS_ENV=test bundle exec rspec"
  end

  desc "高速テスト（:slowと:jsタグのないテスト）のみを実行します"
  task :fast => :environment do
    system "RAILS_ENV=test EXCLUDE_SLOW_TESTS=true EXCLUDE_JS_TESTS=true bundle exec rspec"
  end

  desc "モデルテストのみを実行します"
  task :models => :environment do
    system "RAILS_ENV=test bundle exec rspec spec/models"
  end

  desc "リクエストテスト（統合テスト）のみを実行します"
  task :requests => :environment do
    system "RAILS_ENV=test bundle exec rspec spec/requests"
  end

  desc "サービステストのみを実行します"
  task :services => :environment do
    system "RAILS_ENV=test bundle exec rspec spec/services"
  end

  desc "システムテスト（E2Eテスト）のみを実行します"
  task :system => :environment do
    system "RAILS_ENV=test bundle exec rspec spec/system"
  end

  desc "基本的な操作テスト（smoke）のみを実行します"
  task :smoke => :environment do
    system "RAILS_ENV=test bundle exec rspec --tag group:smoke"
  end

  desc "Docker環境でテストを実行します"
  task :docker_run => :environment do
    system "docker compose -f compose.test.yml run --rm test bundle exec rspec"
  end

  desc "Docker環境で高速テストのみを実行します"
  task :docker_fast => :environment do
    system "docker compose -f compose.test.yml run --rm test sh -c 'EXCLUDE_SLOW_TESTS=true EXCLUDE_JS_TESTS=true bundle exec rspec'"
  end

  desc "Docker環境でE2Eテストのみを実行します"
  task :docker_system => :environment do
    system "docker compose -f compose.test.yml run --rm test bundle exec rspec spec/system"
  end

  desc "Docker環境で基本操作テスト（smoke）のみを実行します"
  task :docker_smoke => :environment do
    system "docker compose -f compose.test.yml run --rm test bundle exec rspec --tag group:smoke"
  end
end

desc "高速テストのみを実行します（test:fastのエイリアス）"
task :fast_test => "test:fast"

desc "スモークテストのみを実行します（test:smokeのエイリアス）"
task :smoke_test => "test:smoke"
