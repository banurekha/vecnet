require 'spec_helper'

describe 'Uploading Generic File' do
  let(:user) { FactoryGirl.create(:user) }
  let(:another_user) { FactoryGirl.create(:user) }

  context "editing my own work" do
    let(:work) { FactoryGirl.create(:public_generic_work, user: user) }
    let(:vecnet_generic_file) {
      FactoryGirl.create_generic_file(:collection, user)
    }
    before do
      login_as user
      visit curation_concern_generic_file_path(vecnet_generic_file)
    end

    it 'there will be a cancel link on the edit page' do
      click_link "Edit"
      expect(page).to have_link('Cancel', curation_concern_generic_work_path(work))
    end
    it 'there will be a cancel link on the attach file page' do
      click_link "Attach a File"
      expect(page).to have_link('Cancel', curation_concern_generic_work_path(work))
    end

  end

  context 'a public work that contains a public file' do
    let(:public_work) { FactoryGirl.create(:public_generic_work, user: another_user) }
    before { upload_my_file(public_work, 'visibility_open') }

    context 'when the user views the public work' do
      before do
        login_as user
        visit curation_concern_generic_work_path(public_work)
      end

      it 'there will be a link to the file show page' do
        public_work.generic_files.count.should == 1
        file = public_work.generic_files.first
        expect(page).to have_link('image.png', curation_concern_generic_file_path(file))
      end
    end
  end

  context 'a public work that contains a private file' do
    let(:public_work) { FactoryGirl.create(:public_generic_work, user: another_user) }
    before { upload_my_file(public_work, 'visibility_restricted') }

    context 'when the user views the public work' do
      before do
        login_as user
        visit curation_concern_generic_work_path(public_work)
      end

      it 'the file name for the private file is not visible' do
        public_work.generic_files.count.should == 1
        file = public_work.generic_files.first
        expect(page).to have_link('File', curation_concern_generic_file_path(file))
        expect(page).to_not have_text('image.png')
      end
    end
  end


  def upload_my_file(work, visibility)
    login_as another_user
    visit new_curation_concern_generic_file_path(work)
    uploaded_file = File.join(fixture_path, 'files/image.png')

    within("form.new_generic_file") do
      fill_in("Title", with: 'image.png')
      attach_file("Upload a file", uploaded_file)
      choose(visibility)
      click_on("Attach to Generic Work")
    end
  end
end

describe 'Viewing a generic file that is private' do
  let(:user) { FactoryGirl.create(:user) }
  let(:work) { FactoryGirl.create(:private_generic_file, title: "Sample file" ) }

  it 'should show a stub indicating we have the work, but it is private' do
    login_as(user)
    visit curation_concern_generic_file_path(work)
    page.should have_content('Unauthorized')
    page.should have_content('The generic file you have tried to access is private')
    page.should have_content("ID: #{work.pid}")
    page.should_not have_content("Sample file")
  end
end