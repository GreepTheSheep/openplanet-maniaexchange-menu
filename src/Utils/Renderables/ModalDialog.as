class ModalDialog : IRenderable
{
    string m_id;
    bool m_firstRender = false;
    bool m_visible = true;

    vec2 m_size = vec2(100, 100);
    int m_flags = UI::WindowFlags::NoSavedSettings | UI::WindowFlags::NoResize | UI::WindowFlags::NoMove;

    ModalDialog(const string &in id)
    {
        m_id = id;
    }

    void Render()
    {
        if (!m_firstRender) {
            UI::OpenPopup(m_id);
        }

        UI::PushStyleVar(UI::StyleVar::WindowPadding, vec2(10, 10));
        UI::PushStyleVar(UI::StyleVar::WindowRounding, 10.0);
        UI::PushStyleVar(UI::StyleVar::FramePadding, vec2(10, 6));
        UI::PushStyleVar(UI::StyleVar::WindowTitleAlign, vec2(.5, .5));
        UI::SetNextWindowSize(int(m_size.x), int(m_size.y));

        bool isOpen = false;

        if (CanClose()) {
            isOpen = UI::BeginPopupModal(m_id, m_visible, m_flags);
        } else {
            isOpen = UI::BeginPopupModal(m_id, m_flags);
        }

        if (isOpen) {
            RenderDialog();
            UI::EndPopup();
        }

        UI::PopStyleVar(4);
    }

    bool CanClose()
    {
        return true;
    }

    bool ShouldDisappear()
    {
        return !m_visible;
    }

    void Close()
    {
        m_visible = false;
        UI::CloseCurrentPopup();
    }

    void RenderDialog()
    {
    }
}