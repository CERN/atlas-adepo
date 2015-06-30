#include "server.h"

int Server::writeParamsFile(QString params_file)
{
    //écriture dans un fichier
    std::ofstream fichier(params_file.toStdString().c_str(), std::ios::out | std::ios::trunc);  // ouverture en écriture avec effacement du fichier ouvert

    if(!fichier) return 0;

    fichier<<"#~ Settings pour les BCAMs"
           <<"set LWDAQ_info_BCAM(daq_password) \"no_password\" \n"
           <<"set LWDAQ_info_BCAM(ambient_exposure_seconds) \"0\" \n"
           <<"set LWDAQ_info_BCAM(counter) \"0\" \n"
           <<"set LWDAQ_info_BCAM(verbose_description) \"  {Spot Position X (um)}  {Spot Position Y (um) or Line Rotation Anticlockwise (mrad)}  {Number of Pixels Above Threshold in Spot}  {Peak Intensity in Spot}  {Accuracy (um)}  {Threshold (counts)}\" \n"
           <<"set LWDAQ_info_BCAM(flash_max_tries) \"30\" \n"
           <<"set LWDAQ_info_BCAM(flash_seconds_max) \"0.1\" \n"
           <<"set LWDAQ_info_BCAM(control) \"Idle\" \n"
           <<"set LWDAQ_info_BCAM(analysis_return_intensity) \"0\" \n"
           <<"set LWDAQ_info_BCAM(daq_image_left) \"20\" \n"
           <<"set LWDAQ_info_BCAM(analysis_show_timing) \"0\" \n"
           <<"set LWDAQ_info_BCAM(daq_image_bottom) \"243\" \n"
           <<"set LWDAQ_info_BCAM(extended_parameters) \"0.6 0.9 0 1\" \n"
           <<"set LWDAQ_info_BCAM(daq_image_right) \"343\" \n"
           <<"set LWDAQ_info_BCAM(text) \".bcam.text\" \n"
           <<"set LWDAQ_info_BCAM(daq_source_device_type) \"2\" \n"
           <<"set LWDAQ_info_BCAM(flash_seconds_step) \"0.000002\" \n"
           <<"set LWDAQ_info_BCAM(daq_image_width) \"344\" \n"
           <<"set LWDAQ_info_BCAM(state_label) \".bcam.buttons.state\" \n"
           <<"set LWDAQ_info_BCAM(daq_source_ip_addr) \"*\" \n"
           <<"set LWDAQ_info_BCAM(analysis_pixel_size_um) \"10\" \n"
           <<"set LWDAQ_info_BCAM(daq_image_height) \"244\" \n"
           <<"set LWDAQ_info_BCAM(window) \".bcam\" \n"
           <<"set LWDAQ_info_BCAM(analysis_show_pixels) \"0\" \n"
           <<"set LWDAQ_info_BCAM(name) \"BCAM\" \n"
           <<"set LWDAQ_info_BCAM(daq_image_top) \"1\" \n"
           <<"set LWDAQ_info_BCAM(photo) \"bcam_photo\" \n"
           <<"set LWDAQ_info_BCAM(flash_num_tries) \"0\" \n"
           <<"set LWDAQ_info_BCAM(flash_seconds_reduce) \"0.1\" \n"
           <<"set LWDAQ_info_BCAM(file_use_daq_bounds) \"0\" \n"
           <<"set LWDAQ_info_BCAM(peak_min) \"100\" \n"
           <<"set LWDAQ_info_BCAM(zoom) \"1\" \n"
           <<"set LWDAQ_info_BCAM(analysis_return_bounds) \"0\" \n"
           <<"set LWDAQ_info_BCAM(delete_old_images) \"1\" \n"
           <<"set LWDAQ_info_BCAM(daq_device_type) \"2\" \n"
           <<"set LWDAQ_info_BCAM(file_try_header) \"1\" \n"
           <<"set LWDAQ_info_BCAM(peak_max) \"160\" \n"
           <<"set LWDAQ_info_BCAM(flash_seconds_transition) \"0.000030\" \n"
           <<"set LWDAQ_info_BCAM(daq_extended) \"0\" \n"
           <<"set LWDAQ_config_BCAM(analysis_threshold) \"10 #\" \n"
           <<"set LWDAQ_config_BCAM(daq_ip_addr) \""<<config.getDriverIpAddress().toStdString()<<"\" \n"
           <<"set LWDAQ_config_BCAM(daq_flash_seconds) \"0.000010\" \n"
           <<"set LWDAQ_config_BCAM(daq_driver_socket) \"5\" \n"
           <<"set LWDAQ_config_BCAM(analysis_num_spots) \"2\" \n"
           <<"set LWDAQ_config_BCAM(image_source) \"daq\" \n"
           <<"set LWDAQ_config_BCAM(daq_subtract_background) \"0\" \n"
           <<"set LWDAQ_config_BCAM(daq_adjust_flash) \"0\" \n"
           <<"set LWDAQ_config_BCAM(daq_source_device_element) \"3 4\" \n"
           <<"set LWDAQ_config_BCAM(daq_source_mux_socket) \"1\" \n"
           <<"set LWDAQ_config_BCAM(file_name) \"./images/BCAM*\" \n"
           <<"set LWDAQ_config_BCAM(intensify) \"exact\" \n"
           <<"set LWDAQ_config_BCAM(memory_name) \"BCAM_0\" \n"
           <<"set LWDAQ_config_BCAM(daq_source_driver_socket) \"8\" \n"
           <<"set LWDAQ_config_BCAM(analysis_enable) \"1\" \n"
           <<"set LWDAQ_config_BCAM(verbose_result) \"0\" \n"
           <<"set LWDAQ_config_BCAM(daq_device_element) \"2\" \n"
           <<"set LWDAQ_config_BCAM(daq_mux_socket) \"1\" \n";

    fichier.close();
    return 1;
}

